import fs from 'node:fs';

const overlaySource = fs.readFileSync('entry/src/main/ets/components/ShatterOverlay.ets', 'utf8');
const tokenSource = fs.readFileSync('entry/src/main/ets/theme/DesignTokens.ets', 'utf8');
const appDesignSource = fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8');
const shatterTokenSource = tokenSource.slice(tokenSource.indexOf('export class ShatterTokens {'));

function requireIncludes(source, marker, message) {
  if (!source.includes(marker)) {
    throw new Error(`${message}: ${marker}`);
  }
}

function readNumber(name) {
  const match = tokenSource.match(new RegExp(`static readonly ${name}: number = ([0-9.]+);`));
  if (match === null) {
    throw new Error(`ShatterTokens 缺少数值：${name}`);
  }
  return Number(match[1]);
}

function readHexColor(source, name) {
  const match = source.match(new RegExp(`static readonly ${name}: string = '(#[0-9A-Fa-f]{6})';`));
  if (match === null) {
    throw new Error(`缺少十六进制颜色：${name}`);
  }
  return match[1];
}

function relativeLuminance(hexColor) {
  const channels = [1, 3, 5].map((index) => Number.parseInt(hexColor.slice(index, index + 2), 16) / 255)
    .map((channel) => channel <= 0.04045
      ? channel / 12.92
      : Math.pow((channel + 0.055) / 1.055, 2.4));
  return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
}

function contrastRatio(firstColor, secondColor) {
  const firstLuminance = relativeLuminance(firstColor);
  const secondLuminance = relativeLuminance(secondColor);
  return (Math.max(firstLuminance, secondLuminance) + 0.05) /
    (Math.min(firstLuminance, secondLuminance) + 0.05);
}

function extractBuilder(source, builderName) {
  const start = source.indexOf(`@Builder\n  ${builderName}()`);
  if (start < 0) {
    return '';
  }
  const bodyStart = source.indexOf('{', start);
  let depth = 0;
  for (let index = bodyStart; index < source.length; index += 1) {
    if (source[index] === '{') {
      depth += 1;
    } else if (source[index] === '}') {
      depth -= 1;
      if (depth === 0) {
        return source.slice(bodyStart, index + 1);
      }
    }
  }
  return '';
}

const mainLifetime = readNumber('mainLifetimeMs');
const haloLifetime = readNumber('haloLifetimeMs');
const driftLifetime = readNumber('driftLifetimeMs');
if (!(mainLifetime < haloLifetime && haloLifetime < driftLifetime)) {
  throw new Error('三层生命周期必须满足 main < halo < drift。');
}

for (const quality of ['Low', 'Medium', 'High']) {
  const mainCount = readNumber(`mainCount${quality}`);
  const haloCount = readNumber(`haloCount${quality}`);
  const driftCount = readNumber(`driftCount${quality}`);
  if (!(mainCount > driftCount && driftCount > haloCount)) {
    throw new Error(`${quality} 数量必须遵循参数表：main > drift > halo。`);
  }
}

const expectedHaloCounts = { Low: 12, Medium: 24, High: 40 };
const expectedDriftCounts = { Low: 30, Medium: 60, High: 90 };
for (const quality of ['Low', 'Medium', 'High']) {
  if (readNumber(`haloCount${quality}`) !== expectedHaloCounts[quality]) {
    throw new Error(`${quality} 光晕密度必须保持 V4 参数的两倍。`);
  }
  if (readNumber(`driftCount${quality}`) !== expectedDriftCounts[quality]) {
    throw new Error(`${quality} 慢漂密度必须保持 V4 参数的 1.5 倍。`);
  }
}
if (readNumber('mainCountMedium') + readNumber('haloCountMedium') + readNumber('driftCountMedium') !== 156) {
  throw new Error('Medium 总粒子数必须为 156。');
}

[
  '@Builder\n  MainBurstLayer()',
  '@Builder\n  HaloLayer()',
  '@Builder\n  DriftLayer()',
  'ParticleType.IMAGE',
  'if (this.layerCount >= 2)',
  'if (this.layerCount >= 3)'
].forEach((marker) => requireIncludes(overlaySource, marker, 'ShatterOverlay 缺少分层实现'));

[
  '@State flashVisible: boolean = false;',
  '@State particlesVisible: boolean = false;',
  'this.clearTimers();',
  'this.flashScale = 0.3;',
  'this.flashOpacity = 0.9;',
  'Circle()',
  ".width('40%')",
  '.fill(ShatterTokens.flashColor)',
  'MotionTokens.durationStagger'
].forEach((marker) => requireIncludes(overlaySource, marker, 'ShatterOverlay 缺少闪光或粒子节奏'));
if (overlaySource.includes('.backgroundColor(')) {
  throw new Error('删除粒子层禁止渲染整块背景，必须依靠粒子自身与页面形成对比。');
}

const shatterVisualSource = `${overlaySource}\n${shatterTokenSource}`;
const translucentBlackColors = [...shatterVisualSource.matchAll(/#([0-9A-Fa-f]{2})000000/g)]
  .map((match) => match[0])
  .filter((color) => color.slice(1, 3).toUpperCase() !== '00');
if (translucentBlackColors.length > 0) {
  throw new Error(`删除粒子层禁止使用半透明黑底：${translucentBlackColors.join(', ')}`);
}
requireIncludes(tokenSource,
  "static readonly mainColorRange: ParticleTuple<ResourceColor, ResourceColor> = ['#365F75', '#D47A18'];",
  'ShatterTokens 主爆必须使用品牌深蓝到高对比琥珀金');
requireIncludes(tokenSource, 'static readonly mainRadius: number = 3;', 'ShatterTokens 主爆粒径必须保持可见性');
requireIncludes(tokenSource, 'static readonly driftRadius: number = 1.5;', 'ShatterTokens 慢漂粒径必须保持可见性');

const pageBackground = readHexColor(appDesignSource, 'pageBackground');
const particleColors = [
  readHexColor(shatterTokenSource, 'haloColorStart'),
  readHexColor(shatterTokenSource, 'haloColorEnd'),
  readHexColor(shatterTokenSource, 'driftColorStart'),
  readHexColor(shatterTokenSource, 'driftColorEnd')
];
for (const particleColor of ['#365F75', '#D47A18', ...particleColors]) {
  const ratio = contrastRatio(pageBackground, particleColor);
  if (ratio < 2.5) {
    throw new Error(`粒子颜色 ${particleColor} 与页面背景 ${pageBackground} 对比度仅 ${ratio.toFixed(2)}:1。`);
  }
}

const mainLayerSource = extractBuilder(overlaySource, 'MainBurstLayer');
const haloLayerSource = extractBuilder(overlaySource, 'HaloLayer');
const driftLayerSource = extractBuilder(overlaySource, 'DriftLayer');
requireIncludes(mainLayerSource, 'ParticleEmitterShape.RECTANGLE', '主爆层必须保持矩形铺满');
requireIncludes(haloLayerSource, 'ParticleEmitterShape.ELLIPSE', '光晕层必须使用椭圆发射器');
requireIncludes(driftLayerSource, 'ParticleEmitterShape.RECTANGLE', '慢漂层必须保持矩形铺满');

const emitterCount = (overlaySource.match(/emitter:/g) ?? []).length;
if (emitterCount !== 3) {
  throw new Error(`ShatterOverlay 必须恰好包含三个 emitter，当前为 ${emitterCount}。`);
}

console.log('shatter layers verified: lifetimes, specified density order, image halo and quality layer gates');
