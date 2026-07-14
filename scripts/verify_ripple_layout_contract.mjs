import fs from 'node:fs';

const rippleSource = fs.readFileSync('entry/src/main/ets/components/motion/RippleTouch.ets', 'utf8');
const projectSource = fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8');
const mySource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

assert(
  /Stack\(\{ alignContent: Alignment\.TopStart \}\) \{\s*this\.content\(\)\s*\}\s*\.overlay\(/m.test(rippleSource),
  'RippleTouch 的布局 Stack 必须只由业务内容测量，水波纹应通过 overlay 叠加。'
);
assert(rippleSource.includes('@Prop clipRadius: number = 0;'), 'RippleTouch 必须暴露圆角裁剪参数。');
assert(rippleSource.includes('this.RippleLayer();'), 'RippleTouch overlay 必须调用独立的水波纹 Builder。');
assert(!/Stack\(\{ alignContent: Alignment\.TopStart \}\) \{[\s\S]*?Circle\(\)/m.test(
  rippleSource.slice(rippleSource.indexOf('build()'))
), '固定尺寸 Circle 不能回到 RippleTouch 的布局 Stack 中。');

assert(
  (projectSource.match(/clipRadius: AppMetrics\.cardRadius/g) ?? []).length === 2,
  '复盘库的待复盘与历史列表都必须按卡片圆角裁剪水波纹。'
);
assert(mySource.includes('clipRadius: AppMetrics.cardRadius'), '“我的”设置行必须按卡片圆角裁剪水波纹。');
assert(
  mySource.includes('@Builder\n  RippleSettingsLinkRowContent(options: RippleSettingsLinkOptions)'),
  '“我的”设置行内容必须使用稳定的实例 Builder。'
);
assert(
  mySource.includes('this.RippleSettingsLinkRowContent(options);'),
  'RippleTouch 闭包必须调用绑定当前页面实例的设置行 Builder。'
);
assert(
  !/content: \(\) => \{\s*SettingsLinkRow\(\{/.test(mySource),
  '不得在 RippleTouch 的 BuilderParam 闭包内直接创建 SettingsLinkRow。'
);

console.log('ripple layout contract verified: overlay does not inflate list rows and card radius clips feedback');
