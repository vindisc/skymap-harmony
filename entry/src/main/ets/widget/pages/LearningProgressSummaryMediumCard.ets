const SUMMARY_CARD_BACKGROUND: string = '#FFFDF8';
const SUMMARY_CARD_TEXT_PRIMARY: string = '#171A1F';
const SUMMARY_CARD_TEXT_SECONDARY: string = '#68707A';
const SUMMARY_CARD_PRIMARY: string = '#356F80';
const SUMMARY_CARD_PRIMARY_SOFT: string = '#DDEFE6';
const SUMMARY_CARD_HINT_BACKGROUND: string = '#F1EADF';
const SUMMARY_CARD_DIVIDER: string = '#E7DFD1';
const SUMMARY_CARD_ACTION_BACKGROUND: string = '#F7F1E7';
const LEARNING_PROGRESS_DIRECT_TARGET_ROUTE: string = 'today_review_direct';

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
    return this.hasPendingReview() ? '继续复盘 →' : '回到首页 →';
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
    Row({ space: 4 }) {
      Text('完成率')
        .fontSize(12)
        .lineHeight(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(SUMMARY_CARD_TEXT_SECONDARY)
        .maxLines(1)

      Text(this.completionRateText)
        .fontSize(19)
        .lineHeight(23)
        .fontWeight(FontWeight.Bold)
        .fontColor(SUMMARY_CARD_PRIMARY)
        .textAlign(TextAlign.End)
        .maxLines(1)
    }
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  PendingDashboard() {
    Column({ space: 0 }) {
      Text('待复盘')
        .fontSize(12)
        .lineHeight(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(SUMMARY_CARD_TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)

      Text(this.pendingCountText)
        .fontSize(50)
        .lineHeight(52)
        .fontWeight(FontWeight.Bold)
        .fontColor(SUMMARY_CARD_TEXT_PRIMARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .layoutWeight(1)
    .height(66)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(16)
    .backgroundColor(SUMMARY_CARD_PRIMARY_SOFT)
  }

  @Builder
  ProgressRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(12)
        .lineHeight(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(SUMMARY_CARD_TEXT_SECONDARY)
        .maxLines(1)

      Blank()

      Text(value)
        .fontSize(17)
        .lineHeight(21)
        .fontWeight(FontWeight.Bold)
        .fontColor(SUMMARY_CARD_PRIMARY)
        .textAlign(TextAlign.End)
        .maxLines(1)
    }
    .width('100%')
    .height(26)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  LearningProgressPanel() {
    Column({ space: 2 }) {
      this.ProgressRow('累计导入', this.totalImportedCountText)
      this.ProgressRow('已完成', this.completedCountText)
    }
    .width(128)
    .height(66)
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .justifyContent(FlexAlign.Center)
    .borderRadius(14)
    .backgroundColor(SUMMARY_CARD_HINT_BACKGROUND)
  }

  @Builder
  ActionHint() {
    Text(this.resolveActionText())
      .fontSize(14)
      .lineHeight(17)
      .fontWeight(FontWeight.Bold)
      .fontColor(SUMMARY_CARD_PRIMARY)
      .textAlign(TextAlign.Center)
      .width('100%')
      .height(24)
      .borderRadius(12)
      .backgroundColor(SUMMARY_CARD_ACTION_BACKGROUND)
  }

  build() {
    Column({ space: 6 }) {
      Row({ space: 10 }) {
        Text(this.title)
          .fontSize(18)
          .lineHeight(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(SUMMARY_CARD_TEXT_PRIMARY)
          .textAlign(TextAlign.Start)
          .layoutWeight(1)
          .maxLines(1)

        this.CompletionBadge()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Divider()
        .strokeWidth(1)
        .color(SUMMARY_CARD_DIVIDER)
        .opacity(0.72)

      Row({ space: 10 }) {
        this.PendingDashboard()

        this.LearningProgressPanel()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      this.ActionHint()
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .borderRadius(18)
    .backgroundColor(SUMMARY_CARD_BACKGROUND)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
