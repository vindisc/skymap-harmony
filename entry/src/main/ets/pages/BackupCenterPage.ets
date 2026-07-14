import common from '@ohos.app.ability.common';
import {
  AppBottomSafeAreaFill,
  AppColors,
  AppMetrics,
  SettingsEntryTone,
  SettingsLinkRow,
  SettingsPageHeader
} from '../components/AppDesign';
import { RippleTouch } from '../components/motion/RippleTouch';
import { DialogService } from '../services/DialogService';
import {
  ReviewLibraryBackupExportResult,
  ReviewLibraryBackupInspection,
  ReviewLibraryBackupRestoreResult,
  ReviewLibraryBackupService
} from '../services/ReviewLibraryBackupService';
import { ToastService, ToastTone } from '../services/ToastService';

interface BackupCenterLinkOptions {
  title: string;
  status: string;
  tone: SettingsEntryTone;
  onTap: () => void;
}

@Entry
@Component
struct BackupCenterPage {
  @State backupItemTotal: number = 0;
  @State isBackupActionRunning: boolean = false;

  private getAbilityContext(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.reloadBackupCount();
  }

  onPageShow(): void {
    this.reloadBackupCount();
  }

  private async reloadBackupCount(): Promise<void> {
    this.backupItemTotal = await ReviewLibraryBackupService.countBackupItems(this.getAbilityContext());
  }

  private formatBackupTime(timestamp: number): string {
    if (timestamp <= 0) {
      return '未知时间';
    }
    const date: Date = new Date(timestamp);
    const pad = (value: number): string => `${value}`.padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
  }

  private async exportLibraryBackup(): Promise<void> {
    if (this.isBackupActionRunning) {
      return;
    }
    this.isBackupActionRunning = true;
    try {
      const result: ReviewLibraryBackupExportResult =
        await ReviewLibraryBackupService.exportToUserFile(this.getAbilityContext());
      if (result.success) {
        ToastService.success(this.getUIContext(), result.message);
      } else if (!result.cancelled) {
        ToastService.error(this.getUIContext(), result.message);
      }
    } catch (error) {
      ToastService.error(this.getUIContext(), `备份失败：${error}`);
    } finally {
      this.isBackupActionRunning = false;
    }
  }

  private async selectLibraryBackup(): Promise<void> {
    if (this.isBackupActionRunning) {
      return;
    }
    this.isBackupActionRunning = true;
    try {
      const inspection: ReviewLibraryBackupInspection =
        await ReviewLibraryBackupService.selectAndInspectBackup(this.getAbilityContext());
      if (!inspection.success) {
        if (!inspection.cancelled) {
          ToastService.error(this.getUIContext(), inspection.message);
        }
        return;
      }
      const imageSummary: string = inspection.missingImageCount > 0
        ? `包含 ${inspection.imageCount} 张照片；旧版备份另有 ${inspection.missingImageCount} 张未包含。`
        : `包含 ${inspection.imageCount} 张照片。`;
      DialogService.confirm(this.getUIContext(), {
        title: `恢复 ${inspection.itemCount} 条复盘？`,
        message: `已选择 ${inspection.fileCount} 个备份，最新备份时间：${this.formatBackupTime(inspection.createdAt)}。${imageSummary}\n恢复后会替换当前 ${this.backupItemTotal} 条复盘，家庭存储密码不会恢复。`,
        cancelText: '取消',
        confirmText: '确认恢复',
        onConfirm: () => {
          this.restoreLibraryBackup(inspection);
        }
      });
    } catch (error) {
      ToastService.error(this.getUIContext(), `读取备份失败：${error}`);
    } finally {
      this.isBackupActionRunning = false;
    }
  }

  private async restoreLibraryBackup(inspection: ReviewLibraryBackupInspection): Promise<void> {
    if (this.isBackupActionRunning) {
      return;
    }
    this.isBackupActionRunning = true;
    try {
      const result: ReviewLibraryBackupRestoreResult =
        await ReviewLibraryBackupService.restoreInspectedBackup(this.getAbilityContext(), inspection);
      if (!result.success) {
        ToastService.error(this.getUIContext(), result.message);
        return;
      }
      ToastService.byTone(
        this.getUIContext(),
        result.message,
        result.settingsRestored ? ToastTone.SUCCESS : ToastTone.WARNING
      );
      await this.reloadBackupCount();
    } catch (error) {
      ToastService.error(this.getUIContext(), `恢复失败，当前数据未被替换：${error}`);
    } finally {
      this.isBackupActionRunning = false;
    }
  }

  @Builder
  BackupLinkRowContent(options: BackupCenterLinkOptions) {
    SettingsLinkRow({
      title: options.title,
      status: options.status,
      tone: options.tone,
      dense: true,
      scaleOnPress: false,
      onTap: options.onTap
    })
  }

  @Builder
  BackupLinkRow(options: BackupCenterLinkOptions) {
    RippleTouch({
      clipRadius: AppMetrics.cardRadius,
      content: () => {
        this.BackupLinkRowContent(options);
      }
    })
      .width('100%')
  }

  @Builder
  BackupActions() {
    Column({ space: AppMetrics.cardGap }) {
      this.BackupLinkRow({
        title: '备份全部复盘',
        status: this.isBackupActionRunning ? '处理中' : `${this.backupItemTotal} 条`,
        tone: this.backupItemTotal > 0 ? SettingsEntryTone.SUCCESS : SettingsEntryTone.MUTED,
        onTap: () => {
          this.exportLibraryBackup();
        }
      })

      this.BackupLinkRow({
        title: '从备份恢复',
        status: this.isBackupActionRunning ? '处理中' : '选择文件',
        tone: SettingsEntryTone.DEFAULT,
        onTap: () => {
          this.selectLibraryBackup();
        }
      })
    }
    .opacity(this.isBackupActionRunning ? 0.68 : 1)
    .width('100%')
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      AppBottomSafeAreaFill()

      Scroll() {
        Column({ space: AppMetrics.sectionGap }) {
          SettingsPageHeader({ title: '备份与恢复' })
          this.BackupActions()
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({
          left: AppMetrics.pagePadding,
          right: AppMetrics.pagePadding,
          top: AppMetrics.pageTopPadding,
          bottom: AppMetrics.pageBottomPadding + AppMetrics.space24
        })
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor(AppColors.pageBackground)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.pageBackground)
  }
}
