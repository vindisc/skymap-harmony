import { Driver, ON } from '@kit.TestKit';
import { describe, it } from '@ohos/hypium';
import { launchTestScenario } from './TestScenarioSupport';

interface SettingsScenarioExpectation {
  scenario: string;
  title: string;
  marker: string;
}

const SETTINGS_SCENARIOS: Array<SettingsScenarioExpectation> = [
  { scenario: 'reviewer_profile', title: '复盘人', marker: '保存' },
  { scenario: 'home_hero_settings', title: '首页图片', marker: '默认首页图' },
  { scenario: 'widget_card_settings', title: '卡片背景', marker: '选定后会立即同步到桌面卡片。回纹以低对比度铺在底层，不影响数据阅读。' },
  { scenario: 'home_storage', title: '家庭存储', marker: '家庭存储地址' },
  { scenario: 'review_settings', title: '设置', marker: '连接与凭据' },
  { scenario: 'sync_center', title: '同步中心', marker: '同步中心' }
];

export default function settingsSmokeTest(): void {
  describe('SettingsSmokeTest', (): void => {
    SETTINGS_SCENARIOS.forEach((item: SettingsScenarioExpectation): void => {
      it(`opens_${item.scenario}`, 0, async (): Promise<void> => {
        const driver: Driver = await launchTestScenario(item.scenario);
        await driver.assertComponentExist(ON.text(item.title));
        await driver.assertComponentExist(ON.text(item.marker));
      });
    });

    it('navigatesFromMyToCardSettings', 0, async (): Promise<void> => {
      const driver: Driver = await launchTestScenario('home');
      const myTab = await driver.findComponent(ON.text('我的'));
      await myTab.click();
      await driver.delayMs(250);
      const cardSettings = await driver.findComponent(ON.text('卡片背景'));
      await cardSettings.click();
      await driver.delayMs(300);
      await driver.assertComponentExist(ON.text('选定后会立即同步到桌面卡片。回纹以低对比度铺在底层，不影响数据阅读。'));
    });
  });
}
