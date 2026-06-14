import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { HOME_STORAGE_PAGE } from '../app/AppRouter';
import { AppColors, AppMetrics, AppPageHeader, AppTypography, PrimaryButton } from '../components/AppDesign';
import { HomeStorageService, HomeStorageSettings } from '../services/HomeStorageService';
import { ReviewSettingsService } from '../services/ReviewSettingsService';
import { formatReviewTime } from '../utils/ImageLayoutUtils';

const APP_VERSION_TEXT: string = '0.1.0 Beta';

@Component
export struct MyPage {
  private loadRequestId: number = 0;
  @State reviewerName: string = '';
  @State draftReviewerName: string = '';
  @State isSavingReviewer: boolean = false;
  @State homeStorageSettings: HomeStorageSettings = HomeStorageService.defaultSettings();
  @State lastUploadedAt: number = 0;

  private getAbilityContext(): common.UIAbilityContext {
    return getContext(this) as common.UIAbilityContext;
  }

  aboutToAppear(): void {
    this.reloadData();
  }

  onPageShow(): void {
    this.reloadData();
  }

  private async reloadData(): Promise<void> {
    const requestId: number = this.loadRequestId + 1;
    this.loadRequestId = requestId;
    const context = this.getAbilityContext();
    const results = await Promise.all([
      ReviewSettingsService.loadReviewerName(context),
      HomeStorageService.loadSettings(context),
      HomeStorageService.loadLastUploadedAt(context)
    ]);
    if (requestId !== this.loadRequestId) {
      return;
    }

    this.reviewerName = results[0] as string;
    this.draftReviewerName = this.reviewerName;
    this.homeStorageSettings = results[1] as HomeStorageSettings;
    this.lastUploadedAt = results[2] as number;
  }

  private isHomeStorageConfigured(): boolean {
    return HomeStorageService.validateSettings(this.homeStorageSettings).length === 0;
  }

  private resolveReviewerSummary(): string {
    return this.reviewerName.length > 0 ? this.reviewerName : '未设置';
  }

  private resolveSyncStatusText(): string {
    return this.isHomeStorageConfigured() ? 'SMB 已连接' : 'SMB 未连接';
  }

  private resolveLastUploadedText(): string {
    return this.lastUploadedAt > 0 ? formatReviewTime(this.lastUploadedAt) : '暂无上传记录';
  }

  private async saveReviewerName(): Promise<void> {
    if (this.isSavingReviewer) {
      return;
    }

    this.isSavingReviewer = true;
    try {
      this.reviewerName = await ReviewSettingsService.saveReviewerName(this.getAbilityContext(), this.draftReviewerName);
      this.draftReviewerName = this.reviewerName;
      promptAction.showToast({ message: '已保存复盘人' });
    } catch (error) {
      promptAction.showToast({ message: '保存失败，请稍后重试' });
    } finally {
      this.isSavingReviewer = false;
    }
  }

  private openHomeStorage(): void {
    router.pushUrl({ url: HOME_STORAGE_PAGE });
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(AppTypography.auxiliary)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.text)
      .width('100%')
  }

  @Builder
  StatusRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(AppTypography.auxiliary)
        .fontColor(AppColors.secondaryText)

      Blank()

      Text(value)
        .fontSize(AppTypography.auxiliary)
        .fontColor(AppColors.text)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }

  @Builder
  LinkRow(title: string, value: string) {
    Row({ space: AppMetrics.space12 }) {
      Column({ space: AppMetrics.space4 }) {
        Text(title)
          .fontSize(AppTypography.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .width('100%')

        Text(value)
          .fontSize(AppTypography.auxiliary)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.auxiliaryLineHeight)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('>')
        .fontSize(AppTypography.body)
        .fontColor(AppColors.mutedText)
    }
    .alignItems(VerticalAlign.Center)
    .padding(AppMetrics.space16)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
    .onClick(() => {
      this.openHomeStorage();
    })
  }

  build() {
    Scroll() {
      Column({ space: AppMetrics.space24 }) {
        AppPageHeader({
          title: '我的',
          subtitle: '管理复盘人、家庭存储和当前版本信息。'
        })

        Column({ space: AppMetrics.space12 }) {
          this.SectionTitle('个人信息')

          Column({ space: AppMetrics.space12 }) {
            Text('复盘人')
              .fontSize(AppTypography.body)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.text)
              .width('100%')

            TextInput({ text: this.draftReviewerName, placeholder: '可留空' })
              .height(48)
              .borderRadius(AppMetrics.cardRadius)
              .fontSize(AppTypography.body)
              .fontColor(AppColors.text)
              .placeholderColor('#9AA1AB')
              .backgroundColor(AppColors.surfaceMuted)
              .padding({ left: AppMetrics.space16, right: AppMetrics.space16 })
              .border({ width: 1, color: AppColors.border })
              .onChange((value: string) => {
                this.draftReviewerName = value;
              })

            PrimaryButton({
              label: this.isSavingReviewer ? '保存中...' : '保存复盘人',
              isDisabled: this.isSavingReviewer,
              onTap: () => {
                this.saveReviewerName();
              }
            })
          }
          .padding(AppMetrics.space16)
          .width('100%')
          .borderRadius(AppMetrics.cardRadius)
          .backgroundColor(AppColors.surface)
          .border({ width: 1, color: AppColors.border })
        }

        Column({ space: AppMetrics.space12 }) {
          this.SectionTitle('家庭存储')
          this.LinkRow(
            '家庭存储',
            this.isHomeStorageConfigured() ? '已配置 SMB，可继续测试连接和修改目录。' : '尚未配置 SMB，可进入填写地址、目录和账号信息。'
          )
        }

        Column({ space: AppMetrics.space12 }) {
          this.SectionTitle('同步状态')

          Column({ space: AppMetrics.space12 }) {
            this.StatusRow('连接状态', this.resolveSyncStatusText())
            this.StatusRow('最近上传时间', this.resolveLastUploadedText())
          }
          .padding(AppMetrics.space16)
          .width('100%')
          .borderRadius(AppMetrics.cardRadius)
          .backgroundColor(AppColors.surface)
          .border({ width: 1, color: AppColors.border })
        }

        Column({ space: AppMetrics.space12 }) {
          this.SectionTitle('关于')

          Column({ space: AppMetrics.space12 }) {
            this.StatusRow('版本号', APP_VERSION_TEXT)
            this.StatusRow('产品说明', 'Skymap Harmony 摄影复盘 Beta')
            this.StatusRow('复盘人', this.resolveReviewerSummary())
          }
          .padding(AppMetrics.space16)
          .width('100%')
          .borderRadius(AppMetrics.cardRadius)
          .backgroundColor(AppColors.surface)
          .border({ width: 1, color: AppColors.border })
        }
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.space24, bottom: AppMetrics.space24 })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
