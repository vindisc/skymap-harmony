import fs from 'node:fs';

const componentDir = 'entry/src/main/ets/components/motion';
const componentMarkers = new Map([
  ['PressReactive.ets', ['export struct PressReactive', 'intensity', 'haptic']],
  ['StaggeredEnter.ets', ['export struct StaggeredEnter', 'batchIndex', 'batchSize', 'delayMs']],
  ['ShimmerBox.ets', ['export struct ShimmerBox', 'boxWidth', 'boxHeight', 'boxRadius']],
  ['CountUpText.ets', ['export struct CountUpText', 'value', 'durationMs', 'suffix']],
  ['BottomSheetContainer.ets', ['export struct BottomSheetContainer', 'visible', 'onClose']],
  ['CeremonyBurst.ets', ['export struct CeremonyBurst', 'kind', 'onFinish', 'Particle']],
  ['RippleTouch.ets', ['export struct RippleTouch', 'tint', 'TouchType.Down']]
]);

for (const [file, markers] of componentMarkers.entries()) {
  const path = `${componentDir}/${file}`;
  if (!fs.existsSync(path)) {
    throw new Error(`缺少动效组件: ${path}`);
  }
  const source = fs.readFileSync(path, 'utf8');
  for (const marker of markers) {
    if (!source.includes(marker)) {
      throw new Error(`${file} 缺少 API/实现标记: ${marker}`);
    }
  }
}

console.log('motion component shapes verified: 7 reusable ArkUI components');
