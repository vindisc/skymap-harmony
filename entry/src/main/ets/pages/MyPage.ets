import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { HOME_STORAGE_PAGE, REVIEWER_PROFILE_PAGE, SYNC_CENTER_PAGE } from '../app/AppRouter';
import { AppColors, AppMetrics, AppPageHeader, AppTypography } from '../components/AppDesign';
import { ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { ReviewCardHistoryService } from '../services/ReviewCardHistoryService';
import { ReviewProjectService } from '../services/ReviewProjectService';
import { HomeStorageService, HomeStorageSettings } from '../services/HomeStorageService';
import { ReviewSettingsService } from '../services/ReviewSettingsService';

const APP_VERSION_TEXT: string = '0.1.0 Beta';
const APP_BUILD_TEXT: string = 'Harmony Beta V1';

@Component
export struct MyPage {
  private loadRequestId: number = 0;
  @State reviewerName: string = '';
  @State homeStorageSettings: HomeStorageSettings = HomeStorageService.defaultSettings();
  @State reviewCount: number = 0;
  @State validReviewCount: number = 0;

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

    const historyItems: Array<ReviewCardHistoryItem> = await ReviewCardHistoryService.load(context);
    if (requestId !== this.loadRequestId) {
      return;
    }
    const summary = ReviewProjectService.buildHomeSummary(historyItems);
    this.reviewCount = summary.recordCount;
    this.validReviewCount = summary.stats.validCount;

    this.reviewerName = await ReviewSettingsService.loadReviewerName(context);
    if (requestId !== this.loadRequestId) {
      return;
    }

    this.homeStorageSettings = await HomeStorageService.loadSettings(context);
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

  private resolveHomeStorageDetail(): string {
    if (!this.isHomeStorageConfigured()) {
      return '先配置地址和共享目录';
    }
    return `${this.homeStorageSettings.smbHost} · ${this.homeStorageSettings.smbShareName}`;
  }

  private resolveSyncSummary(): string {
    return this.isHomeStorageConfigured() ? '家庭存储可用' : '需要配置家庭存储';
  }

  private resolveProfileName(): string {
    return this.reviewerName.length > 0 ? this.reviewerName : '见遇';
  }

  private openReviewerProfile(): void {
    router.pushUrl({ url: REVIEWER_PROFILE_PAGE });
  }

  private openHomeStorage(): void {
    router.pushUrl({ url: HOME_STORAGE_PAGE });
  }

  private openSyncCenter(): void {
    router.pushUrl({ url: SYNC_CENTER_PAGE });
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(AppTypography.caption)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.secondaryText)
      .width('100%')
  }

  @Builder
  StatusRow(label: string, value: string) {
    Row({ space: AppMetrics.space16 }) {
      Text(label)
        .fontSize(AppTypography.auxiliary)
        .fontColor(AppColors.secondaryText)
        .width(72)

      Text(value)
        .fontSize(AppTypography.auxiliary)
        .fontColor(AppColors.text)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }

  @Builder
  LinkRow(title: string, value: string, onTap: () => void) {
    Row({ space: AppMetrics.cardGap }) {
      Column({ space: AppMetrics.space8 }) {
        Text(title)
          .fontSize(AppTypography.cardTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.cardTitleLineHeight)
          .width('100%')

        Text(value)
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.captionLineHeight)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(AppTypography.cardTitle)
        .fontColor(AppColors.mutedText)
        .opacity(0.56)
    }
    .alignItems(VerticalAlign.Center)
    .padding(AppMetrics.cardPadding)
    .width('100%')
    .constraintSize({ minHeight: 68, maxHeight: 76 })
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })

    .onClick(() => {
      onTap();
    })
  }

  @Builder
  IdentityCard() {
    Column({ space: AppMetrics.cardGap }) {
      Column({ space: AppMetrics.space8 }) {
        Text(this.resolveProfileName())
          .fontSize(AppTypography.profileName)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.profileNameLineHeight)
          .width('100%')

        Text('摄影复盘 Beta 用户')
          .fontSize(AppTypography.body)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.bodyLineHeight)
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')

      Text(`${this.reviewCount} 次复盘 · ${this.validReviewCount} 次成立`)
        .fontSize(AppTypography.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.bodyLineHeight)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(AppMetrics.cardPadding)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }

  build() {
    Scroll() {
      Column({ space: AppMetrics.sectionGap }) {
        AppPageHeader({
          title: '我的',
          subtitle: '管理复盘人、家庭存储和版本信息'
        })

        this.IdentityCard()

        this.SectionTitle('设置')

        Column({ space: AppMetrics.cardGap }) {
          this.LinkRow('复盘人', this.resolveReviewerSummary(), () => {
            this.openReviewerProfile();
          })
        }

        this.SectionTitle('同步')

        Column({ space: AppMetrics.cardGap }) {
          this.LinkRow('同步中心', this.resolveSyncSummary(), () => {
            this.openSyncCenter();
          })

          this.LinkRow(
            '家庭存储',
            this.resolveHomeStorageDetail(),
            () => {
              this.openHomeStorage();
            }
          )
        }

        this.SectionTitle('应用')

        this.LinkRow('关于', `${APP_VERSION_TEXT} · ${APP_BUILD_TEXT}`, () => {
        })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding, top: AppMetrics.pageTopPadding, bottom: AppMetrics.tabBarHeight + AppMetrics.pageBottomPadding })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor(AppColors.pageBackground)
  }
}
