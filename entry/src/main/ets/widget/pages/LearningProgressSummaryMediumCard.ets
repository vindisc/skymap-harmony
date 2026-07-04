const SUMMARY_CARD_BACKGROUND: string = '#FFFDF8';
const SUMMARY_CARD_TEXT_PRIMARY: string = '#171A1F';
const SUMMARY_CARD_TEXT_SECONDARY: string = '#68707A';
const SUMMARY_CARD_PRIMARY: string = '#356F80';
const SUMMARY_CARD_PRIMARY_SOFT: string = '#DDEFE6';
const SUMMARY_CARD_PROGRESS_SOFT: string = '#EEF5EF';
const SUMMARY_CARD_HINT_SOFT: string = '#F2F6F1';
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
    Row({ space: 4 }) {
      Text('完成率')
        .fontSize(12)
        .lineHeight(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(SUMMARY_CARD_TEXT_SECONDARY)
        .maxLines(1)

      Text(this.completionRateText)
        .fontSize(17)
        .lineHeight(21)
        .fontWeight(FontWeight.Bold)
        .fontColor(SUMMARY_CARD_PRIMARY)
        .textAlign(TextAlign.End)
        .maxLines(1)
    }
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  PendingDashboard() {
    Column({ space: 2 }) {
      Text(this.pendingCountText)
        .fontSize(48)
        .lineHeight(50)
        .fontWeight(FontWeight.Bold)
        .fontColor(SUMMARY_CARD_TEXT_PRIMARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)

      Text('待复盘')
        .fontSize(13)
        .lineHeight(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(SUMMARY_CARD_TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width('100%')
    .height(64)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(14)
    .backgroundColor(SUMMARY_CARD_PRIMARY_SOFT)
  }

  @Builder
  LearningProgressSummary() {
    Column({ space: 3 }) {
      Text('已完成')
        .fontSize(12)
        .lineHeight(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(SUMMARY_CARD_TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)

      Text(`${this.completedCountText} / ${this.totalImportedCountText}`)
        .fontSize(27)
        .lineHeight(31)
        .fontWeight(FontWeight.Bold)
        .fontColor(SUMMARY_CARD_PRIMARY)
        .textAlign(TextAlign.Center)
        .maxLines(1)
    }
    .width('100%')
    .height(64)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(14)
    .backgroundColor(SUMMARY_CARD_PROGRESS_SOFT)
  }

  @Builder
  ActionHint() {
    Row({ space: 6 }) {
      Text(this.resolveActionText())
        .fontSize(14)
        .lineHeight(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(SUMMARY_CARD_PRIMARY)
        .maxLines(1)

      Text('›')
        .fontSize(18)
        .lineHeight(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(SUMMARY_CARD_PRIMARY)
        .maxLines(1)
    }
    .width('100%')
    .height(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .borderRadius(12)
    .backgroundColor(SUMMARY_CARD_HINT_SOFT)
  }

  build() {
    Column({ space: 7 }) {
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
      .height(22)
      .alignItems(VerticalAlign.Center)

      Row({ space: 10 }) {
        Column() {
          this.PendingDashboard()
        }
        .layoutWeight(55)
        .height(68)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column() {
          this.LearningProgressSummary()
        }
        .layoutWeight(45)
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
    .padding({ left: 12, right: 12, top: 10, bottom: 12 })
    .borderRadius(18)
    .backgroundColor(SUMMARY_CARD_BACKGROUND)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
