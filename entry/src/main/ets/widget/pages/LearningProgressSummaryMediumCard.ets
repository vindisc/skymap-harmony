const SUMMARY_CARD_BACKGROUND: string = '#FFFDF8';
const SUMMARY_CARD_TEXT_PRIMARY: string = '#171A1F';
const SUMMARY_CARD_TEXT_SECONDARY: string = '#68707A';
const SUMMARY_CARD_PRIMARY: string = '#356F80';
const SUMMARY_CARD_PRIMARY_SOFT: string = '#DDEFE6';
const SUMMARY_CARD_HINT_BACKGROUND: string = '#F1EADF';
const SUMMARY_CARD_DIVIDER: string = '#E7DFD1';
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
    Column({ space: 0 }) {
      Text(this.completionRateText)
        .fontSize(25)
        .lineHeight(29)
        .fontWeight(FontWeight.Bold)
        .fontColor(SUMMARY_CARD_PRIMARY)
        .textAlign(TextAlign.End)
        .maxLines(1)

      Text('完成率')
        .fontSize(11)
        .lineHeight(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(SUMMARY_CARD_TEXT_SECONDARY)
        .textAlign(TextAlign.End)
        .maxLines(1)
    }
    .alignItems(HorizontalAlign.End)
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .borderRadius(14)
    .backgroundColor(SUMMARY_CARD_PRIMARY_SOFT)
  }

  @Builder
  MetricRow(label: string, value: string, valueColor: string, rowBackground: string, valueSize: number) {
    Row() {
      Text(label)
        .fontSize(13)
        .lineHeight(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(SUMMARY_CARD_TEXT_SECONDARY)
        .maxLines(1)

      Blank()

      Text(value)
        .fontSize(valueSize)
        .lineHeight(valueSize + 4)
        .fontWeight(FontWeight.Bold)
        .fontColor(valueColor)
        .textAlign(TextAlign.End)
        .maxLines(1)
    }
    .width('100%')
    .height(36)
    .padding({ left: 12, right: 12 })
    .alignItems(VerticalAlign.Center)
    .borderRadius(12)
    .backgroundColor(rowBackground)
  }

  build() {
    Column({ space: 10 }) {
      Row({ space: 10 }) {
        Text(this.title)
          .fontSize(18)
          .lineHeight(24)
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

      Column({ space: 8 }) {
        this.MetricRow('待复盘', this.pendingCountText, SUMMARY_CARD_TEXT_PRIMARY, SUMMARY_CARD_PRIMARY_SOFT, 24)
        this.MetricRow('累计导入', this.totalImportedCountText, SUMMARY_CARD_PRIMARY, SUMMARY_CARD_HINT_BACKGROUND, 19)
        this.MetricRow('已完成', this.completedCountText, SUMMARY_CARD_PRIMARY, SUMMARY_CARD_HINT_BACKGROUND, 19)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding(14)
    .borderRadius(18)
    .backgroundColor(SUMMARY_CARD_BACKGROUND)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
