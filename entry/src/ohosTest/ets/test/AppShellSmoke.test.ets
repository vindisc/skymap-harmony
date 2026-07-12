import { Driver, ON } from '@kit.TestKit';
import { describe, it } from '@ohos/hypium';

export default function appShellSmokeTest(): void {
  describe('AppShellSmokeTest', (): void => {
    it('showsRootTabs', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      await driver.delayMs(800);
      await driver.assertComponentExist(ON.text('首页'));
      await driver.assertComponentExist(ON.text('复盘库'));
      await driver.assertComponentExist(ON.text('统计'));
      await driver.assertComponentExist(ON.text('我的'));
    });

    it('opensStatsTab', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const statsTab = await driver.findComponent(ON.text('统计'));
      await statsTab.click();
      await driver.delayMs(300);
      await driver.assertComponentExist(ON.text('学习进度'));
    });

    it('opensMyTab', 0, async (): Promise<void> => {
      const driver: Driver = Driver.create();
      const myTab = await driver.findComponent(ON.text('我的'));
      await myTab.click();
      await driver.delayMs(300);
      await driver.assertComponentExist(ON.text('复盘人'));
      await driver.assertComponentExist(ON.text('卡片背景'));
    });
  });
}
