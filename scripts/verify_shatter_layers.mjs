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

[
  '@Builder\n  MainBurstLayer()',
  '@Builder\n  HaloLayer()',
  '@Builder\n  DriftLayer()',
  'ParticleType.IMAGE',
  'if (this.layerCount >= 2)',
  'if (this.layerCount >= 3)'
].forEach((marker) => requireIncludes(overlaySource, marker, 'ShatterOverlay 缺少分层实现'));

const emitterCount = (overlaySource.match(/emitter:/g) ?? []).length;
if (emitterCount !== 3) {
  throw new Error(`ShatterOverlay 必须恰好包含三个 emitter，当前为 ${emitterCount}。`);
}

console.log('shatter layers verified: lifetimes, specified density order, image halo and quality layer gates');
