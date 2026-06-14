import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { HOME_STORAGE_PAGE, REVIEWER_PROFILE_PAGE } from '../app/AppRouter';
import { AppColors, AppMetrics, AppPageHeader, AppTypography } from '../components/AppDesign';
import { HomeStorageService, HomeStorageSettings } from '../services/HomeStorageService';
import { ReviewSettingsService } from '../services/ReviewSettingsService';

const APP_VERSION_TEXT: string = '0.1.0 Beta';
const APP_BUILD_TEXT: string = 'Harmony Beta V1';

@Component
export struct MyPage {
  private loadRequestId: number = 0;
  @State reviewerName: string = '';
  @State homeStorageSettings: HomeStorageSettings = HomeStorageService.defaultSettings();

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
      HomeStorageService.loadSettings(context)
    ]);
    if (requestId !== this.loadRequestId) {
      return;
    }

    this.reviewerName = results[0] as string;
    this.homeStorageSettings = results[1] as HomeStorageSettings;
  }

  private isHomeStorageConfigured(): boolean {
    return HomeStorageService.validateSettings(this.homeStorageSettings).length === 0;
  }

  private resolveReviewerSummary(): string {
    return this.reviewerName.length > 0 ? this.reviewerName : '未设置';
  }

  private resolveHomeStorageSummary(): string {
    return this.isHomeStorageConfigured() ? '已配置' : '未配置';
  }

  private openReviewerProfile(): void {
    router.pushUrl({ url: REVIEWER_PROFILE_PAGE });
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
  LinkRow(title: string, value: string, onTap: () => void) {
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
      onTap();
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
          this.LinkRow('复盘人', this.resolveReviewerSummary(), () => {
            this.openReviewerProfile();
          })
        }

        Column({ space: AppMetrics.space12 }) {
          this.SectionTitle('家庭存储')
          this.LinkRow(
            '家庭存储',
            this.resolveHomeStorageSummary(),
            () => {
              this.openHomeStorage();
            }
          )
        }

        Column({ space: AppMetrics.space12 }) {
          this.SectionTitle('关于')

          Column({ space: AppMetrics.space12 }) {
            this.StatusRow('版本号', APP_VERSION_TEXT)
            this.StatusRow('Build', APP_BUILD_TEXT)
            this.StatusRow('产品说明', 'Skymap Harmony 摄影复盘 Beta')
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
