const TODAY_CARD_BACKGROUND: string = '#FFFDF8';
const TODAY_CARD_TEXT_PRIMARY: string = '#171A1F';
const TODAY_CARD_TEXT_SECONDARY: string = '#68707A';
const TODAY_CARD_PRIMARY: string = '#356F80';
const TODAY_CARD_PRIMARY_SOFT: string = '#DDEFE6';
const TODAY_CARD_HINT_BACKGROUND: string = '#F1EADF';

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

  private resolveMainText(): string {
    if (this.hasPendingReview()) {
      return `待复盘 ${this.resolvePendingCount()} 张`;
    }
    return '今日已清空';
  }

  private resolveHintText(): string {
    return this.hasPendingReview() ? '点击继续' : '暂无待复盘';
  }

  build() {
    FormLink({
      action: 'router',
      abilityName: 'EntryAbility',
      params: {
        targetRoute: this.targetRoute
      }
    }) {
      Column({ space: 12 }) {
        Text('今日复盘')
          .fontSize(18)
          .lineHeight(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(TODAY_CARD_TEXT_PRIMARY)
          .textAlign(TextAlign.Start)
          .width('100%')

        Column({ space: 6 }) {
          Text(this.resolveMainText())
            .fontSize(this.hasPendingReview() ? 24 : 22)
            .lineHeight(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.hasPendingReview() ? TODAY_CARD_TEXT_PRIMARY : TODAY_CARD_PRIMARY)
            .textAlign(TextAlign.Center)

          Text(this.resolveHintText())
            .fontSize(13)
            .lineHeight(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(TODAY_CARD_TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
        .borderRadius(14)
        .backgroundColor(this.hasPendingReview() ? TODAY_CARD_PRIMARY_SOFT : TODAY_CARD_HINT_BACKGROUND)
      }
      .width('100%')
      .height('100%')
      .padding(12)
      .borderRadius(18)
      .backgroundColor(TODAY_CARD_BACKGROUND)
    }
    .width('100%')
    .height('100%')
  }
}
