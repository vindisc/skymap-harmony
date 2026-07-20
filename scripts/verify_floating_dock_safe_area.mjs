import fs from 'node:fs';

const sources = {
  design: fs.readFileSync('entry/src/main/ets/components/AppDesign.ets', 'utf8'),
  settingsForm: fs.readFileSync('entry/src/main/ets/components/SettingsForm.ets', 'utf8'),
  editor: fs.readFileSync('entry/src/main/ets/pages/EditorPage.ets', 'utf8'),
  preview: fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8'),
  homeStorage: fs.readFileSync('entry/src/main/ets/pages/HomeStoragePage.ets', 'utf8'),
  reviewSettings: fs.readFileSync('entry/src/main/ets/pages/ReviewSettingsPage.ets', 'utf8'),
  reviewerProfile: fs.readFileSync('entry/src/main/ets/pages/ReviewerProfilePage.ets', 'utf8'),
  syncCenter: fs.readFileSync('entry/src/main/ets/pages/SyncCenterPage.ets', 'utf8')
};

function assertIncludes(source, marker, message) {
  if (!source.includes(marker)) {
    throw new Error(message);
  }
}

assertIncludes(
  sources.design,
  'static readonly floatingDockBottomPadding: number = FLOATING_DOCK_BOTTOM_PADDING;',
  'Floating docks must keep their buttons above the system gesture area.'
);
assertIncludes(
  sources.design,
  'static readonly floatingDockReservedHeight: number = LayoutTokens.PrimaryButtonHeight + 16 + FLOATING_DOCK_BOTTOM_PADDING;',
  'Scroll content must derive floating dock clearance from shared control and safe-area tokens.'
);

for (const [name, source] of [
  ['SettingsActionBar', sources.settingsForm],
  ['PreviewPage', sources.preview]
]) {
  assertIncludes(
    source,
    'bottom: AppMetrics.floatingDockBottomPadding',
    `${name} must use the shared bottom safe padding instead of a local fixed value.`
  );
}

assertIncludes(
  sources.editor,
  'AppMetrics.floatingDockReservedHeight + AppMetrics.floatingDockScrollClearance',
  'EditorPage inline action row must reserve the shared bottom safe-area clearance in scroll content.'
);

for (const [name, source] of [
  ['HomeStoragePage', sources.homeStorage],
  ['ReviewSettingsPage', sources.reviewSettings],
  ['ReviewerProfilePage', sources.reviewerProfile],
  ['SyncCenterPage', sources.syncCenter],
  ['EditorPage', sources.editor]
]) {
  assertIncludes(
    source,
    'AppMetrics.floatingDockReservedHeight + AppMetrics.floatingDockScrollClearance',
    `${name} must reserve scroll space for the lifted floating dock.`
  );
}

assertIncludes(
  sources.preview,
  '+ AppMetrics.floatingDockBottomPadding\n      + AppMetrics.floatingDockScrollClearance;',
  'PreviewPage reading content must reserve the raised export dock and scroll clearance.'
);

console.log('floating dock safe-area layout verified.');
