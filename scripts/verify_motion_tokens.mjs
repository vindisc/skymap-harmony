import fs from 'node:fs';

const tokenPath = 'entry/src/main/ets/theme/DesignTokens.ets';
const contextPath = 'entry/src/main/ets/theme/MotionQualityContext.ets';
const tokenSource = fs.readFileSync(tokenPath, 'utf8');
const contextSource = fs.readFileSync(contextPath, 'utf8');

const requiredTokens = [
  'durationFrame',
  'durationHero',
  'durationCeremony',
  'durationStagger',
  'durationStaggerLong',
  'curveEmphasized',
  'curveSpringSoft',
  'curveSpringResponsive',
  'curveSpringBouncy',
  'curveDeceleratedLanding',
  'offsetEnterY',
  'offsetEnterYCard',
  'offsetEnterYSheet',
  'offsetExitYToast',
  'scalePressedHard',
  'scaleCeremony',
  'scaleHeroIntro'
];

for (const token of requiredTokens) {
  if (!tokenSource.includes(`static readonly ${token}`)) {
    throw new Error(`缺少动效 Token: ${token}`);
  }
}

for (const api of ['resolveDuration', 'resolveCurve', 'shouldPlayCeremony', 'shouldPlayShatter', 'tryAcquireCeremonySlot']) {
  if (!contextSource.includes(`static ${api}`)) {
    throw new Error(`MotionQualityContext 缺少 API: ${api}`);
  }
}

console.log('motion tokens verified: duration, curve, offset, scale and quality context');
