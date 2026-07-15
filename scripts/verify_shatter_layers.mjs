import fs from 'node:fs';

const overlaySource = fs.readFileSync('entry/src/main/ets/components/ShatterOverlay.ets', 'utf8');
const tokenSource = fs.readFileSync('entry/src/main/ets/theme/DesignTokens.ets', 'utf8');

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
  '@State scrimActive: boolean = false;',
  '@State particlesVisible: boolean = false;',
  'this.clearTimers();',
  'this.flashScale = 0.3;',
  'this.flashOpacity = 0.9;',
  'Circle()',
  ".width('40%')",
  ".backgroundColor(this.scrimActive ? '#14000000' : '#00000000')",
  'MotionTokens.durationStagger',
  'MotionTokens.shatterDurationMs'
].forEach((marker) => requireIncludes(overlaySource, marker, 'ShatterOverlay 缺少闪光或暗化节奏'));
requireIncludes(tokenSource,
  "static readonly mainColorRange: ParticleTuple<ResourceColor, ResourceColor> = ['#FFFFFF', '#FFD98A'];",
  'ShatterTokens 主爆必须使用白到暖金色');

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
