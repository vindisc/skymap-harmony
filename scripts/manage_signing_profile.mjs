import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const trackedProfilePath = path.join(root, 'build-profile.json5');
const localProfilePath = path.resolve(
  process.env.SKYMAP_SIGNING_PROFILE || path.join(root, 'build-profile.local.json5')
);

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
    return JSON.parse(stripJsonComments(fs.readFileSync(filePath, 'utf8')));
  } catch (error) {
    fail(`${label}不是可解析的 JSON/JSONC：${error.message}`);
  }
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
  const source = fs.readFileSync(trackedProfilePath, 'utf8');
  const profile = readProfile(trackedProfilePath, '仓库 build-profile.json5');
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
  const product = findDefaultProduct(localProfile, '本机签名配置');
  product.signingConfig = signingConfig.name;
  fs.writeFileSync(trackedProfilePath, `${JSON.stringify(localProfile, null, 2)}\n`, { mode: 0o600 });
  console.log(`已临时启用 ${requestedMode} 签名；构建结束后必须恢复仓库配置。`);
}

function deactivate() {
  const profile = readProfile(trackedProfilePath, '仓库 build-profile.json5');
  if (profile?.app && Object.hasOwn(profile.app, 'signingConfigs')) {
    delete profile.app.signingConfigs;
  }
  const products = profile?.app?.products;
  if (Array.isArray(products)) {
    products.forEach((product) => {
      if (product && Object.hasOwn(product, 'signingConfig')) {
        delete product.signingConfig;
      }
    });
  }
  fs.writeFileSync(trackedProfilePath, `${JSON.stringify(profile, null, 2)}\n`);
  console.log('已临时停用签名；构建结束后必须恢复原配置。');
}

const [command = 'status', mode] = process.argv.slice(2);

if (command === 'assert-safe') {
  assertTrackedProfileSafe();
  console.log('仓库 build-profile.json5 已净化：未包含签名材料或本机路径。');
} else if (command === 'status') {
  assertTrackedProfileSafe();
  const modes = availableModes();
  console.log('仓库签名模式：unsigned');
  console.log(`本机可用签名：${modes.length > 0 ? modes.join(', ') : '无'}`);
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
} else {
  fail('支持命令：status、assert-safe、verify-local、activate、deactivate。');
}
