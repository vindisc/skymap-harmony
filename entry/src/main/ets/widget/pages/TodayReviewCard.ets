const TODAY_CARD_BACKGROUND: string = '#FFFFFF';
const TODAY_CARD_CONTENT_BACKGROUND: string = '#F8F6F1';
const TODAY_CARD_TEXT_PRIMARY: string = '#0D1117';
const TODAY_CARD_TEXT_SECONDARY: string = '#68707A';
const TODAY_CARD_THEME_COLOR: string = '#356F80';
const TODAY_REVIEW_DIRECT_TARGET_ROUTE: string = 'today_review_direct';

// 圆角
const TODAY_CARD_OUTER_RADIUS: number = 24;
const TODAY_CARD_PADDING: number = 16;

let todayReviewCardStorage: LocalStorage = new LocalStorage();

@Entry(todayReviewCardStorage)
@Component
struct TodayReviewCard {
  @LocalStorageProp('pendingCountText') pendingCountText: string = '0';
  @LocalStorageProp('targetRoute') targetRoute: string = 'home';

  private resolvePendingCount(): number {
    const count: number = Number(this.pendingCountText);
    return Number.isNaN(count) ? 0 : Math.max(0, count);
  }

  private hasPendingReview(): boolean {
    return this.resolvePendingCount() > 0;
  }

  private resolveHintText(): string {
    return this.hasPendingReview() ? '继续复盘' : '暂无待复盘';
  }

  private openTargetRoute(): void {
    postCardAction(this, {
      action: 'router',
      moduleName: 'entry',
      abilityName: 'EntryAbility',
      params: {
        targetRoute: this.hasPendingReview() ? TODAY_REVIEW_DIRECT_TARGET_ROUTE : this.targetRoute
      }
    });
  }

  build() {
    Column({ space: 14 }) {
      Text('今日复盘')
        .fontSize(16)
        .lineHeight(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(TODAY_CARD_TEXT_PRIMARY)
        .textAlign(TextAlign.Start)
        .width('100%')
        .maxLines(1)

      Column({ space: 8 }) {
        Text(`${this.resolvePendingCount()}`)
          .fontSize(36)
          .lineHeight(40)
          .fontWeight(900)
          .fontColor(TODAY_CARD_THEME_COLOR)
          .letterSpacing(-1)
          .textAlign(TextAlign.Start)
          .width('100%')

        if (this.hasPendingReview()) {
          Text('张待复盘')
            .fontSize(13)
            .lineHeight(18)
            .fontWeight(FontWeight.Regular)
            .fontColor(TODAY_CARD_TEXT_SECONDARY)
            .textAlign(TextAlign.Start)
            .width('100%')
        } else {
          Text('已清空')
            .fontSize(13)
            .lineHeight(18)
            .fontWeight(FontWeight.Regular)
            .fontColor(TODAY_CARD_TEXT_SECONDARY)
            .textAlign(TextAlign.Start)
            .width('100%')
        }
      }
      .width('100%')

      Row({ space: 6 }) {
        Text(this.resolveHintText())
          .fontSize(13)
          .lineHeight(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.hasPendingReview() ? '#FFFDF8' : TODAY_CARD_TEXT_SECONDARY)
          .maxLines(1)

        if (this.hasPendingReview()) {
          Text('→')
            .fontSize(15)
            .lineHeight(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFDF8')
            .maxLines(1)
        }
      }
      .width('100%')
      .height(30)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .padding(14)
      .borderRadius(12)
      .backgroundColor(this.hasPendingReview() ? TODAY_CARD_THEME_COLOR : '#F1EADF')
    }
    .width('100%')
    .height('100%')
    .padding(TODAY_CARD_PADDING)
    .borderRadius(TODAY_CARD_OUTER_RADIUS)
    .backgroundColor(TODAY_CARD_CONTENT_BACKGROUND)
    .justifyContent(FlexAlign.Start)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
