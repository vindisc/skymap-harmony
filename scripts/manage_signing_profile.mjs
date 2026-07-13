import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const trackedProfilePath = path.join(root, 'build-profile.json5');
const localProfilePath = path.resolve(
  process.env.SKYMAP_SIGNING_PROFILE || path.join(root, 'build-profile.local.json5')
);
const ideJavaHome = '/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home';

function fail(message) {
  console.error(message);
  process.exit(1);
}

function stripJsonComments(source) {
  let output = '';
  let quote = '';
  let escaped = false;

  for (let index = 0; index < source.length; index += 1) {
    const char = source[index];
    const next = source[index + 1];

    if (quote.length > 0) {
      output += char;
      if (escaped) {
        escaped = false;
      } else if (char === '\\') {
        escaped = true;
      } else if (char === quote) {
        quote = '';
      }
      continue;
    }

    if (char === '"') {
      quote = char;
      output += char;
      continue;
    }

    if (char === '/' && next === '/') {
      while (index < source.length && source[index] !== '\n') {
        index += 1;
      }
      output += '\n';
      continue;
    }

    if (char === '/' && next === '*') {
      index += 2;
      while (index < source.length && !(source[index] === '*' && source[index + 1] === '/')) {
        if (source[index] === '\n') {
          output += '\n';
        }
        index += 1;
      }
      index += 1;
      continue;
    }

    output += char;
  }

  return output;
}

function readProfile(filePath, label) {
  if (!fs.existsSync(filePath)) {
    fail(`${label}不存在：${path.basename(filePath)}`);
  }

  try {
    return parseProfileSource(fs.readFileSync(filePath, 'utf8'));
  } catch (error) {
    fail(`${label}不是可解析的 JSON/JSONC：${error.message}`);
  }
}

function parseProfileSource(source) {
  return JSON.parse(stripJsonComments(source));
}

function serializeProfile(profile) {
  return `${JSON.stringify(profile, null, 2)}\n`;
}

function sanitizeProfile(profile) {
  const sanitized = JSON.parse(JSON.stringify(profile));
  if (sanitized?.app && Object.hasOwn(sanitized.app, 'signingConfigs')) {
    delete sanitized.app.signingConfigs;
  }
  const products = sanitized?.app?.products;
  if (Array.isArray(products)) {
    products.forEach((product) => {
      if (product && Object.hasOwn(product, 'signingConfig')) {
        delete product.signingConfig;
      }
    });
  }
  return sanitized;
}

function findDefaultProduct(profile, label) {
  const products = profile?.app?.products;
  if (!Array.isArray(products)) {
    fail(`${label}缺少 app.products。`);
  }
  const product = products.find((item) => item?.name === 'default');
  if (!product) {
    fail(`${label}缺少 default product。`);
  }
  return product;
}

function assertTrackedProfileSafe() {
  const indexResult = spawnSync('git', ['show', ':build-profile.json5'], {
    cwd: root,
    encoding: 'utf8'
  });
  if (indexResult.status !== 0) {
    fail(`无法读取 Git 暂存区中的 build-profile.json5：${indexResult.stderr.trim()}`);
  }
  const source = indexResult.stdout;
  const profile = parseProfileSource(source);
  const products = profile?.app?.products || [];
  const forbiddenMarkers = [
    'storePassword',
    'keyPassword',
    'storeFile',
    'certpath',
    'signingConfigs',
    '/Users/'
  ];

  for (const marker of forbiddenMarkers) {
    if (source.includes(marker)) {
      fail(`仓库 build-profile.json5 含本机签名字段：${marker}`);
    }
  }
  if (products.some((product) => Object.hasOwn(product, 'signingConfig'))) {
    fail('仓库 build-profile.json5 不得固定 signingConfig。');
  }
}

function applySigningOverlay(baseProfile, localProfile, requestedMode) {
  const profile = sanitizeProfile(baseProfile);
  const signingConfig = resolveSigningConfig(localProfile, requestedMode);
  if (!profile.app || typeof profile.app !== 'object') {
    fail('build-profile.json5 缺少 app。');
  }
  profile.app.signingConfigs = [signingConfig];
  const product = findDefaultProduct(profile, 'build-profile.json5');
  product.signingConfig = signingConfig.name;
  return profile;
}

function runGitConfig(args, allowMissing = false) {
  const result = spawnSync('git', ['config', '--local', ...args], {
    cwd: root,
    encoding: 'utf8'
  });
  if (result.status !== 0 && !(allowMissing && result.status === 5)) {
    fail(`写入本仓库 Git 配置失败：${result.stderr.trim()}`);
  }
  return result.stdout.trim();
}

function refreshTrackedProfileStat() {
  const cleanHashResult = spawnSync('git', ['hash-object', '--path=build-profile.json5', 'build-profile.json5'], {
    cwd: root,
    encoding: 'utf8'
  });
  const indexHashResult = spawnSync('git', ['rev-parse', ':build-profile.json5'], {
    cwd: root,
    encoding: 'utf8'
  });
  if (cleanHashResult.status !== 0 || indexHashResult.status !== 0 ||
      cleanHashResult.stdout.trim() !== indexHashResult.stdout.trim()) {
    fail('本机签名 clean filter 未能还原当前 Git 暂存区基线。');
  }
  const addResult = spawnSync('git', ['add', '--', 'build-profile.json5'], {
    cwd: root,
    encoding: 'utf8'
  });
  if (addResult.status !== 0) {
    fail(`刷新 build-profile.json5 Git 状态失败：${addResult.stderr.trim()}`);
  }
}

function isIdeFilterEnabled() {
  const result = spawnSync('git', ['config', '--local', '--get', 'filter.skymap-signing.required'], {
    cwd: root,
    encoding: 'utf8'
  });
  return result.status === 0 && result.stdout.trim() === 'true';
}

function updateDevEcoRunJavaHome(enabled) {
  const workspacePath = path.join(root, '.idea', 'workspace.xml');
  if (!fs.existsSync(workspacePath)) {
    return;
  }
  let source = fs.readFileSync(workspacePath, 'utf8');
  const configurationPattern = /<configuration\b[^>]*type="(?:HotReLoadTask|OhosDebugTask)"[\s\S]*?<\/configuration>/g;
  source = source.replace(configurationPattern, (configuration) => {
    return configuration.replace(
      /<ENVIRONMENT_VARIABLES>([\s\S]*?)<\/ENVIRONMENT_VARIABLES>/,
      (_match, encodedValue) => {
        let variables = [];
        try {
          variables = JSON.parse(encodedValue.replaceAll('&quot;', '"').replaceAll('&amp;', '&'));
        } catch (_error) {
          variables = [];
        }
        variables = variables.filter((item) => item?.name !== 'JAVA_HOME');
        if (enabled) {
          variables.push({ name: 'JAVA_HOME', value: ideJavaHome });
        }
        const serialized = JSON.stringify(variables)
          .replaceAll('&', '&amp;')
          .replaceAll('"', '&quot;');
        return `<ENVIRONMENT_VARIABLES>${serialized}</ENVIRONMENT_VARIABLES>`;
      }
    );
  });
  fs.writeFileSync(workspacePath, source);
}

function enableIdeSigning() {
  assertTrackedProfileSafe();
  const attributesPath = path.join(root, '.gitattributes');
  if (!fs.existsSync(attributesPath) ||
      !fs.readFileSync(attributesPath, 'utf8').includes('/build-profile.json5 filter=skymap-signing')) {
    fail('.gitattributes 缺少 build-profile.json5 本地签名过滤规则。');
  }
  const localProfile = readProfile(localProfilePath, '本机签名配置');
  const signingConfig = resolveSigningConfig(localProfile, 'debug');
  validateMaterial(signingConfig, 'debug');
  runGitConfig(['filter.skymap-signing.clean', 'node scripts/manage_signing_profile.mjs filter-clean']);
  runGitConfig(['filter.skymap-signing.smudge', 'node scripts/manage_signing_profile.mjs filter-smudge']);
  runGitConfig(['filter.skymap-signing.required', 'true']);

  const currentProfile = readProfile(trackedProfilePath, 'build-profile.json5');
  const ideProfile = applySigningOverlay(currentProfile, localProfile, 'debug');
  fs.writeFileSync(trackedProfilePath, serializeProfile(ideProfile), { mode: 0o600 });
  updateDevEcoRunJavaHome(true);
  refreshTrackedProfileStat();
  console.log('已启用 IDE 本地 Debug 签名和 Zulu 11：重启 DevEco 后可直接运行，Git 暂存内容会自动净化。');
}

function disableIdeSigning() {
  const currentProfile = readProfile(trackedProfilePath, 'build-profile.json5');
  fs.writeFileSync(trackedProfilePath, serializeProfile(sanitizeProfile(currentProfile)));
  runGitConfig(['--unset-all', 'filter.skymap-signing.clean'], true);
  runGitConfig(['--unset-all', 'filter.skymap-signing.smudge'], true);
  runGitConfig(['--unset-all', 'filter.skymap-signing.required'], true);
  updateDevEcoRunJavaHome(false);
  refreshTrackedProfileStat();
  console.log('已停用 IDE 本地签名，工作树恢复无签名配置。');
}

function filterClean() {
  const source = fs.readFileSync(0, 'utf8');
  process.stdout.write(serializeProfile(sanitizeProfile(parseProfileSource(source))));
}

function filterSmudge() {
  const source = fs.readFileSync(0, 'utf8');
  const baseProfile = parseProfileSource(source);
  if (!fs.existsSync(localProfilePath)) {
    process.stdout.write(serializeProfile(sanitizeProfile(baseProfile)));
    return;
  }
  const localProfile = readProfile(localProfilePath, '本机签名配置');
  process.stdout.write(serializeProfile(applySigningOverlay(baseProfile, localProfile, 'debug')));
}

function resolveSigningConfig(profile, requestedMode) {
  const signingConfigs = profile?.app?.signingConfigs;
  if (!Array.isArray(signingConfigs)) {
    fail('本机签名配置缺少 app.signingConfigs。');
  }

  const candidateNames = requestedMode === 'debug' ? ['debug', 'default'] : ['release'];
  const signingConfig = signingConfigs.find((item) => candidateNames.includes(item?.name));
  if (!signingConfig) {
    fail(`本机签名配置没有可用的 ${requestedMode} signingConfig。`);
  }
  return signingConfig;
}

function validateMaterial(signingConfig, requestedMode) {
  const material = signingConfig?.material;
  const requiredTextFields = ['storePassword', 'keyAlias', 'keyPassword', 'signAlg'];
  const requiredFileFields = ['storeFile', 'profile', 'certpath'];

  if (!material || typeof material !== 'object') {
    fail(`${requestedMode} signingConfig 缺少 material。`);
  }
  for (const field of requiredTextFields) {
    if (typeof material[field] !== 'string' || material[field].trim().length === 0) {
      fail(`${requestedMode} signingConfig 缺少 ${field}。`);
    }
  }
  for (const field of requiredFileFields) {
    if (typeof material[field] !== 'string' || material[field].trim().length === 0) {
      fail(`${requestedMode} signingConfig 缺少 ${field}。`);
    }
    if (!fs.existsSync(material[field])) {
      fail(`${requestedMode} signingConfig 的 ${field} 文件不存在。`);
    }
  }
}

function availableModes() {
  if (!fs.existsSync(localProfilePath)) {
    return [];
  }
  const profile = readProfile(localProfilePath, '本机签名配置');
  const names = new Set((profile?.app?.signingConfigs || []).map((item) => item?.name));
  const modes = [];
  if (names.has('debug') || names.has('default')) {
    modes.push('debug');
  }
  if (names.has('release')) {
    modes.push('release');
  }
  return modes;
}

function activate(requestedMode) {
  assertTrackedProfileSafe();
  const localProfile = readProfile(localProfilePath, '本机签名配置');
  const signingConfig = resolveSigningConfig(localProfile, requestedMode);
  validateMaterial(signingConfig, requestedMode);
  const currentProfile = readProfile(trackedProfilePath, 'build-profile.json5');
  const activatedProfile = applySigningOverlay(currentProfile, localProfile, requestedMode);
  fs.writeFileSync(trackedProfilePath, serializeProfile(activatedProfile), { mode: 0o600 });
  console.log(`已临时启用 ${requestedMode} 签名；构建结束后必须恢复仓库配置。`);
}

function deactivate() {
  const profile = readProfile(trackedProfilePath, '仓库 build-profile.json5');
  fs.writeFileSync(trackedProfilePath, serializeProfile(sanitizeProfile(profile)));
  console.log('已临时停用签名；构建结束后必须恢复原配置。');
}

function migrateTrackedSigning() {
  const trackedProfile = readProfile(trackedProfilePath, '仓库 build-profile.json5');
  const trackedConfigs = trackedProfile?.app?.signingConfigs;
  if (!Array.isArray(trackedConfigs) || trackedConfigs.length === 0) {
    fail('仓库 build-profile.json5 没有可迁移的签名配置。');
  }

  const localProfile = fs.existsSync(localProfilePath)
    ? readProfile(localProfilePath, '本机签名配置')
    : JSON.parse(JSON.stringify(trackedProfile));
  if (!localProfile.app || typeof localProfile.app !== 'object') {
    fail('本机签名配置缺少 app。');
  }
  const localConfigs = Array.isArray(localProfile.app.signingConfigs)
    ? localProfile.app.signingConfigs
    : [];
  const mergedConfigs = localConfigs.slice();
  for (const config of trackedConfigs) {
    const existingIndex = mergedConfigs.findIndex((item) => item?.name === config?.name);
    if (existingIndex >= 0) {
      mergedConfigs[existingIndex] = config;
    } else {
      mergedConfigs.push(config);
    }
  }
  localProfile.app.signingConfigs = mergedConfigs;
  fs.writeFileSync(localProfilePath, `${JSON.stringify(localProfile, null, 2)}\n`, { mode: 0o600 });
  deactivate();
  console.log(`已把 ${trackedConfigs.length} 组本机签名迁移到忽略文件，并净化仓库配置。`);
}

function migrateDevEcoSyncSigning() {
  const syncOutputPath = path.join(root, '.hvigor', 'outputs', 'sync', 'output.json');
  if (!fs.existsSync(syncOutputPath)) {
    fail('未找到 DevEco 同步缓存，请先在 IDE 中完成一次签名配置同步。');
  }
  const syncOutput = readProfile(syncOutputPath, 'DevEco 同步缓存');
  const cachedConfigs = syncOutput?.['ohos-project']?.PROFILE_OPT?.app?.signingConfigs;
  if (!Array.isArray(cachedConfigs) || cachedConfigs.length === 0) {
    fail('DevEco 同步缓存中没有签名配置。');
  }
  const localProfile = readProfile(localProfilePath, '本机签名配置');
  if (!localProfile.app || typeof localProfile.app !== 'object') {
    fail('本机签名配置缺少 app。');
  }
  const localConfigs = Array.isArray(localProfile.app.signingConfigs)
    ? localProfile.app.signingConfigs.slice()
    : [];
  for (const config of cachedConfigs) {
    validateMaterial(config, config?.name || 'DevEco');
    const existingIndex = localConfigs.findIndex((item) => item?.name === config?.name);
    if (existingIndex >= 0) {
      localConfigs[existingIndex] = config;
    } else {
      localConfigs.push(config);
    }
  }
  localProfile.app.signingConfigs = localConfigs;
  fs.writeFileSync(localProfilePath, serializeProfile(localProfile), { mode: 0o600 });
  console.log(`已从 DevEco 同步缓存迁移 ${cachedConfigs.length} 组本机签名配置。`);
}

const [command = 'status', mode] = process.argv.slice(2);

if (command === 'filter-clean') {
  filterClean();
} else if (command === 'filter-smudge') {
  filterSmudge();
} else if (command === 'assert-safe') {
  assertTrackedProfileSafe();
  console.log('仓库 build-profile.json5 已净化：未包含签名材料或本机路径。');
} else if (command === 'status') {
  assertTrackedProfileSafe();
  const modes = availableModes();
  console.log('仓库签名模式：unsigned');
  console.log(`本机可用签名：${modes.length > 0 ? modes.join(', ') : '无'}`);
  console.log(`IDE 直接运行签名：${isIdeFilterEnabled() ? '已启用' : '未启用'}`);
} else if (command === 'refresh-status') {
  if (isIdeFilterEnabled()) {
    refreshTrackedProfileStat();
  }
} else if (command === 'verify-local') {
  if (!['debug', 'release'].includes(mode)) {
    fail('用法：node scripts/manage_signing_profile.mjs verify-local <debug|release>');
  }
  const localProfile = readProfile(localProfilePath, '本机签名配置');
  const signingConfig = resolveSigningConfig(localProfile, mode);
  validateMaterial(signingConfig, mode);
  console.log(`${mode} 本机签名配置完整，材料文件均存在。`);
} else if (command === 'activate') {
  if (!['debug', 'release'].includes(mode)) {
    fail('用法：node scripts/manage_signing_profile.mjs activate <debug|release>');
  }
  activate(mode);
} else if (command === 'deactivate') {
  deactivate();
} else if (command === 'migrate-tracked') {
  migrateTrackedSigning();
} else if (command === 'migrate-ide-cache') {
  migrateDevEcoSyncSigning();
} else if (command === 'ide-enable') {
  enableIdeSigning();
} else if (command === 'ide-disable') {
  disableIdeSigning();
} else {
  fail('支持命令：status、refresh-status、assert-safe、verify-local、activate、deactivate、migrate-tracked、migrate-ide-cache、ide-enable、ide-disable。');
}
