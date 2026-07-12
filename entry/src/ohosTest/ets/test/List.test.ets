import appShellSmokeTest from './AppShellSmoke.test';
import reviewFlowSmokeTest from './ReviewFlowSmoke.test';
import settingsSmokeTest from './SettingsSmoke.test';

export default function testsuite(): void {
  appShellSmokeTest();
  reviewFlowSmokeTest();
  settingsSmokeTest();
}
