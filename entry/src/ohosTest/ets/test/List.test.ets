import appShellSmokeTest from './AppShellSmoke.test';
import reviewFlowSmokeTest from './ReviewFlowSmoke.test';
import settingsSmokeTest from './SettingsSmoke.test';
import dataBehaviorTest from './DataBehavior.test';
import exifIdentityTest from './ExifIdentity.test';

export default function testsuite(): void {
  appShellSmokeTest();
  reviewFlowSmokeTest();
  settingsSmokeTest();
  dataBehaviorTest();
  exifIdentityTest();
}
