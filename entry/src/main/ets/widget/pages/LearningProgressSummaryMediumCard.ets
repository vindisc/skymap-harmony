const SUMMARY_CARD_BACKGROUND: string = '#FFFDF8';
const SUMMARY_CARD_TEXT_PRIMARY: string = '#0D1117';
const SUMMARY_CARD_TEXT_SECONDARY: string = '#68707A';
const SUMMARY_CARD_PRIMARY: string = '#356F80';
const SUMMARY_CARD_PRIMARY_SOFT: string = '#D8EDE5';
const SUMMARY_CARD_PROGRESS_SOFT: string = '#E8F3EC';
const SUMMARY_CARD_ACTION_DISABLED: string = '#E7ECE5';
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
    Column({ space: 1 }) {
      Text(this.pendingCountText)
        .fontSize(32)
        .lineHeight(36)
        .fontWeight(900)
        .fontColor(SUMMARY_CARD_TEXT_PRIMARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .letterSpacing(-1)

      Text('待复盘')
        .fontSize(11)
        .lineHeight(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(SUMMARY_CARD_TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width('100%')
    .height(68)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(14)
    .backgroundColor(SUMMARY_CARD_PRIMARY_SOFT)
  }

  @Builder
  LearningProgressSummary() {
    Column({ space: 3 }) {
      Text('已完成')
        .fontSize(11)
        .lineHeight(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(SUMMARY_CARD_TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)

      Text(`${this.completedCountText} / ${this.totalImportedCountText}`)
        .fontSize(24)
        .lineHeight(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(SUMMARY_CARD_PRIMARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width('100%')
    .height(68)
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
    .height(30)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .borderRadius(11)
    .backgroundColor(this.hasPendingReview() ? SUMMARY_CARD_PRIMARY : SUMMARY_CARD_ACTION_DISABLED)
  }

  build() {
    Column({ space: 10 }) {
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

      Row({ space: 10 }) {
        Column() {
          this.PendingDashboard()
        }
        .layoutWeight(50)
        .height(68)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column() {
          this.LearningProgressSummary()
        }
        .layoutWeight(50)
        .height(68)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height(68)
      .alignItems(VerticalAlign.Center)

      this.ActionHint()
    }
    .width('100%')
    .height('100%')
    .padding({ left: 14, right: 14, top: 11, bottom: 12 })
    .borderRadius(18)
    .backgroundColor(SUMMARY_CARD_BACKGROUND)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
