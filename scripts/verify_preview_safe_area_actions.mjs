import fs from 'node:fs';

const previewSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const entryAbilitySource = fs.readFileSync('entry/src/main/ets/entryability/EntryAbility.ets', 'utf8');
const appDesignSource = fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

assert(!previewSource.includes('AppBottomSafeAreaFill()'), 'PreviewPage must not draw an extra standalone bottom safe-area strip.');
assert(previewSource.includes('.backgroundColor(AppColors.pageBackground)\n      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])\n      .hitTestBehavior(HitTestMode.Transparent)'), 'Preview floating dock must own the bottom safe area background.');
assert(previewSource.includes('.height(\'100%\')\n    .backgroundColor(AppColors.pageBackground)\n    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])'), 'Preview reading page must expand page background into bottom safe area.');
assert(previewSource.includes('.justifyContent(FlexAlign.Start)\n          .alignItems(HorizontalAlign.Start)\n          .constraintSize({ minHeight: \'100%\' })'), 'Preview reading content must stay top-aligned when the record is shorter than the viewport.');
assert(previewSource.includes('.height(\'100%\')\n    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])\n    .zIndex(10)'), 'Preview export menu sheet must cover the bottom safe area.');
assert(previewSource.includes(".fontColor(this.isPressed('cancel-export') ? AppColors.onPrimary : AppColors.primary)"), 'Export sheet cancel button must use primary-colored text.');
assert(previewSource.includes(".backgroundColor(this.isPressed('cancel-export') ? AppColors.primary : AppColors.primarySoft)"), 'Export sheet cancel button must use a visible primary-tinted background.');
assert(previewSource.includes("this.updatePressedAction(event, 'cancel-export', false);"), 'Export sheet cancel button must have pressed feedback.');
assert(entryAbilitySource.includes('setWindowLayoutFullScreen(true)'), 'Main window must use immersive layout so pages can own the bottom navigation area.');
assert(entryAbilitySource.includes("const APP_TRANSPARENT: string = '#00000000';"), 'System bars must use a transparent color token.');
assert(entryAbilitySource.includes('navigationBarColor: APP_TRANSPARENT'), 'Navigation bar must not draw a separate bottom strip color.');
assert(appDesignSource.includes('static readonly pageTopPadding: number = 52;'), 'Immersive window layout must keep page content below the status bar.');

if (failed) {
  process.exit(1);
}

console.log('preview safe-area actions: dock safe area and cancel button contrast verified');
