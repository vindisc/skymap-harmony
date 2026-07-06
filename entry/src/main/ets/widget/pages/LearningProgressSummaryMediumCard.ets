const SUMMARY_CARD_BACKGROUND: string = '#FFFDF8';
const SUMMARY_CARD_TEXT_PRIMARY: string = '#0D1117';
const SUMMARY_CARD_TEXT_SECONDARY: string = '#68707A';
const SUMMARY_CARD_PRIMARY: string = '#356F80';
const SUMMARY_CARD_PRIMARY_SOFT: string = '#D8EDE5';
const SUMMARY_CARD_PROGRESS_SOFT: string = '#E8F3EC';
const SUMMARY_CARD_ACTION_DISABLED: string = '#E7ECE5';
const LEARNING_PROGRESS_DIRECT_TARGET_ROUTE: string = 'today_review_direct';

// 2*4 中型卡片在真机桌面里底部空间很紧：上方两个指标块必须保持紧凑，
// 给底部“继续复盘”留出呼吸感。调整这些值时同步更新 verify_learning_progress_widget.mjs。
const SUMMARY_CARD_COLUMN_GAP: number = 9;
const SUMMARY_CARD_METRIC_ROW_GAP: number = 10;
const SUMMARY_CARD_METRIC_ROW_HEIGHT: number = 56;
const SUMMARY_CARD_METRIC_TILE_HEIGHT: number = 50;
const SUMMARY_CARD_METRIC_NUMBER_SIZE: number = 26;
const SUMMARY_CARD_METRIC_NUMBER_LINE_HEIGHT: number = 30;
const SUMMARY_CARD_METRIC_LABEL_SIZE: number = 10;
const SUMMARY_CARD_METRIC_LABEL_LINE_HEIGHT: number = 14;
const SUMMARY_CARD_PROGRESS_NUMBER_SIZE: number = 22;
const SUMMARY_CARD_PROGRESS_NUMBER_LINE_HEIGHT: number = 26;
const SUMMARY_CARD_ACTION_HEIGHT: number = 30;
const SUMMARY_CARD_HORIZONTAL_PADDING: number = 14;
const SUMMARY_CARD_TOP_PADDING: number = 11;
const SUMMARY_CARD_BOTTOM_PADDING: number = 15;

let learningProgressSummaryCardStorage: LocalStorage = new LocalStorage();

@Entry(learningProgressSummaryCardStorage)
@Component
struct LearningProgressSummaryMediumCard {
  @LocalStorageProp('title') title: string = '摄影学习';
  @LocalStorageProp('pendingCountText') pendingCountText: string = '0';
  @LocalStorageProp('totalImportedCountText') totalImportedCountText: string = '0';
  @LocalStorageProp('completedCountText') completedCountText: string = '0';
  @LocalStorageProp('completionRateText') completionRateText: string = '--';
  @LocalStorageProp('targetRoute') targetRoute: string = 'home';

  private resolvePendingCount(): number {
    const count: number = Number(this.pendingCountText);
    return Number.isNaN(count) ? 0 : Math.max(0, count);
  }

  private hasPendingReview(): boolean {
    return this.resolvePendingCount() > 0;
  }

  private resolveActionText(): string {
    return this.hasPendingReview() ? '继续复盘' : '回到首页';
  }

  private openTargetRoute(): void {
    postCardAction(this, {
      action: 'router',
      moduleName: 'entry',
      abilityName: 'EntryAbility',
      params: {
        targetRoute: this.hasPendingReview() ? LEARNING_PROGRESS_DIRECT_TARGET_ROUTE : this.targetRoute
      }
    });
  }

  @Builder
  CompletionBadge() {
    Text(this.completionRateText)
      .fontSize(13)
      .lineHeight(17)
      .fontWeight(FontWeight.Bold)
      .fontColor(SUMMARY_CARD_PRIMARY)
      .maxLines(1)
  }

  @Builder
  PendingDashboard() {
    Column({ space: 0 }) {
      Text(this.pendingCountText)
        .fontSize(SUMMARY_CARD_METRIC_NUMBER_SIZE)
        .lineHeight(SUMMARY_CARD_METRIC_NUMBER_LINE_HEIGHT)
        .fontWeight(900)
        .fontColor(SUMMARY_CARD_TEXT_PRIMARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .letterSpacing(-1)

      Text('待复盘')
        .fontSize(SUMMARY_CARD_METRIC_LABEL_SIZE)
        .lineHeight(SUMMARY_CARD_METRIC_LABEL_LINE_HEIGHT)
        .fontWeight(FontWeight.Medium)
        .fontColor(SUMMARY_CARD_TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width('100%')
    .height(SUMMARY_CARD_METRIC_TILE_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(14)
    .backgroundColor(SUMMARY_CARD_PRIMARY_SOFT)
  }

  @Builder
  LearningProgressSummary() {
    Column({ space: 2 }) {
      Text('已完成')
        .fontSize(SUMMARY_CARD_METRIC_LABEL_SIZE)
        .lineHeight(SUMMARY_CARD_METRIC_LABEL_LINE_HEIGHT)
        .fontWeight(FontWeight.Medium)
        .fontColor(SUMMARY_CARD_TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)

      Text(`${this.completedCountText} / ${this.totalImportedCountText}`)
        .fontSize(SUMMARY_CARD_PROGRESS_NUMBER_SIZE)
        .lineHeight(SUMMARY_CARD_PROGRESS_NUMBER_LINE_HEIGHT)
        .fontWeight(FontWeight.Bold)
        .fontColor(SUMMARY_CARD_PRIMARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width('100%')
    .height(SUMMARY_CARD_METRIC_TILE_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(14)
    .backgroundColor(SUMMARY_CARD_PROGRESS_SOFT)
  }

  @Builder
  ActionHint() {
    Row({ space: 6 }) {
      Text(this.resolveActionText())
        .fontSize(13)
        .lineHeight(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.hasPendingReview() ? '#FFFDF8' : SUMMARY_CARD_TEXT_SECONDARY)
        .maxLines(1)

      Text('→')
        .fontSize(15)
        .lineHeight(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.hasPendingReview() ? '#FFFDF8' : SUMMARY_CARD_TEXT_SECONDARY)
        .maxLines(1)
    }
    .width('100%')
    .height(SUMMARY_CARD_ACTION_HEIGHT)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .borderRadius(11)
    .backgroundColor(this.hasPendingReview() ? SUMMARY_CARD_PRIMARY : SUMMARY_CARD_ACTION_DISABLED)
  }

  build() {
    Column({ space: SUMMARY_CARD_COLUMN_GAP }) {
      Row({ space: 6 }) {
        Text(this.title)
          .fontSize(15)
          .lineHeight(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(SUMMARY_CARD_TEXT_PRIMARY)
          .textAlign(TextAlign.Start)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('完成')
          .fontSize(10)
          .fontColor(SUMMARY_CARD_TEXT_SECONDARY)

        this.CompletionBadge()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: SUMMARY_CARD_METRIC_ROW_GAP }) {
        Column() {
          this.PendingDashboard()
        }
        .layoutWeight(50)
        .height(SUMMARY_CARD_METRIC_ROW_HEIGHT)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column() {
          this.LearningProgressSummary()
        }
        .layoutWeight(50)
        .height(SUMMARY_CARD_METRIC_ROW_HEIGHT)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height(SUMMARY_CARD_METRIC_ROW_HEIGHT)
      .alignItems(VerticalAlign.Center)

      this.ActionHint()
    }
    .width('100%')
    .height('100%')
    .padding({
      left: SUMMARY_CARD_HORIZONTAL_PADDING,
      right: SUMMARY_CARD_HORIZONTAL_PADDING,
      top: SUMMARY_CARD_TOP_PADDING,
      bottom: SUMMARY_CARD_BOTTOM_PADDING
    })
    .borderRadius(18)
    .backgroundColor(SUMMARY_CARD_BACKGROUND)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
