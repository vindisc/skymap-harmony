import { Driver, ON } from '@kit.TestKit';
import { describe, it } from '@ohos/hypium';
import { launchTestScenario } from './TestScenarioSupport';

export default function reviewFlowSmokeTest(): void {
  describe('ReviewFlowSmokeTest', (): void => {
    it('showsHorizontalEditor', 0, async (): Promise<void> => {
      const driver: Driver = await launchTestScenario('editor_horizontal');
      await driver.assertComponentExist(ON.text('标题'));
      await driver.assertComponentExist(ON.text('视觉落点'));
      await driver.assertComponentExist(ON.hint('这张照片是否成立'));
      await driver.assertComponentExist(ON.text('摄影复盘卡'));
    });

    it('savesEditorAndEntersPreview', 0, async (): Promise<void> => {
      const driver: Driver = await launchTestScenario('editor_vertical');
      const titleInput = await driver.findComponent(ON.hint('这张照片是否成立'));
      await titleInput.clearText();
      await titleInput.inputText('UI 自动化完整链路');
      await driver.pressBack();
      const editorScroll = await driver.findComponent(ON.scrollable(true));
      const saveButton = await editorScroll.scrollSearch(ON.text('💾 保存'));
      await saveButton.click();
      await driver.delayMs(900);
      await driver.assertComponentExist(ON.text('复盘记录'));
      await driver.assertComponentExist(ON.text('导出图片'));
      await driver.assertComponentExist(ON.text('UI 自动化完整链路'));
    });

    it('opensPreviewExportMenu', 0, async (): Promise<void> => {
      const driver: Driver = await launchTestScenario('preview_square');
      await driver.assertComponentExist(ON.text('复盘记录'));
      const moreButton = await driver.findComponent(ON.text('更多'));
      await moreButton.click();
      await driver.delayMs(250);
      await driver.assertComponentExist(ON.text('导出当前复盘'));
      await driver.assertComponentExist(ON.text('取消'));
    });

    it('rendersLongTextPreview', 0, async (): Promise<void> => {
      const driver: Driver = await launchTestScenario('preview_long_text');
      await driver.assertComponentExist(ON.text('自动化测试复盘'));
      await driver.assertComponentExist(ON.text('复盘记录'));
      await driver.assertComponentExist(ON.text('导出图片'));
    });
  });
}
