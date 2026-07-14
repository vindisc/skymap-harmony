import fs from 'node:fs';

const countUpSource = fs.readFileSync('entry/src/main/ets/components/motion/CountUpText.ets', 'utf8');
const rippleSource = fs.readFileSync('entry/src/main/ets/components/motion/RippleTouch.ets', 'utf8');
const bottomSheetSource = fs.readFileSync('entry/src/main/ets/components/motion/BottomSheetContainer.ets', 'utf8');
const editorSource = fs.readFileSync('entry/src/main/ets/pages/EditorPage.ets', 'utf8');
const entryAbilitySource = fs.readFileSync('entry/src/main/ets/entryability/EntryAbility.ets', 'utf8');
const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');
const homeSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const statsSource = fs.readFileSync('entry/src/main/ets/pages/StatsPage.ets', 'utf8');
const previewSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');

function assertIncludes(source, marker, message) {
  if (!source.includes(marker)) {
    throw new Error(`${message}: ${marker}`);
  }
}

function assertNotIncludes(source, marker, message) {
  if (source.includes(marker)) {
    throw new Error(`${message}: ${marker}`);
  }
}

assertIncludes(countUpSource, 'private celebrateTimerId: number = -1;', 'CountUpText must track its terminal timer');
assertIncludes(countUpSource, 'clearTimeout(this.celebrateTimerId);', 'CountUpText must clear its terminal timer');
assertIncludes(rippleSource, 'private startTimerId: number = -1;', 'RippleTouch must track its next-frame timer');
assertIncludes(rippleSource, 'clearTimeout(this.startTimerId);', 'RippleTouch must clear its next-frame timer');
assertIncludes(bottomSheetSource, '}, MotionTokens.durationFrame);', 'Bottom sheet presentation must wait one frame');
assertNotIncludes(bottomSheetSource, '}, 0);', 'Bottom sheet must not merge rendered and presented into one frame');
assertNotIncludes(editorSource, 'keepSavingLockedForCeremony', 'Editor must not retain the removed ceremony save lock');
assertNotIncludes(editorSource, '@State ceremonyVisible', 'Editor must not keep the removed ceremony state');
assertIncludes(editorSource, 'finally {\n      this.isSaving = false;', 'Editor must release the save lock after save navigation');
assertIncludes(entryAbilitySource, 'await MotionQualityContext.initialize(this.context);', 'Motion quality must load before initial content');
assertNotIncludes(appShellSource, 'MotionQualityContext.initialize(', 'App shell must not race motion initialization after first render');
assertIncludes(homeSource, 'MotionTokens.durationStaggerLong * 2', 'Home stagger must use motion tokens');
assertNotIncludes(homeSource, 'MotionTokens.durationStagger, 120, 200', 'Home stagger must not use raw delays');
const homePageShowSource = homeSource.slice(homeSource.indexOf('onPageShow(): void {'), homeSource.indexOf('refreshHomeData(): void {'));
assertNotIncludes(homePageShowSource, 'this.playIntro();', 'Home must not replay its intro when returning from a child page');
const statsPageShowSource = statsSource.slice(statsSource.indexOf('onPageShow(): void {'), statsSource.indexOf('private ensureCeremonySubscription(): void {'));
assertNotIncludes(statsPageShowSource, 'this.playIntro();', 'Stats must not replay its intro when returning from a child page');
assertIncludes(statsSource, 'private introTimerIds: Array<number> = [];', 'Stats must track stagger timers');
assertIncludes(statsSource, 'this.clearIntroTimers();', 'Stats must clear stagger timers before leaving');
assertNotIncludes(previewSource, 'content: this.', 'BuilderParam content must not receive an unbound page builder');

console.log('motion lifecycle guards verified: timers, page re-entry, save lock, startup quality, builder binding');
