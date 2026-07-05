const TODAY_CARD_BACKGROUND: string = '#FFFDF8';
const TODAY_CARD_TEXT_PRIMARY: string = '#171A1F';
const TODAY_CARD_TEXT_SECONDARY: string = '#68707A';
const TODAY_CARD_PRIMARY: string = '#356F80';
const TODAY_CARD_HINT_BACKGROUND: string = '#F1EADF';
const TODAY_REVIEW_DIRECT_TARGET_ROUTE: string = 'today_review_direct';

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
        .fontSize(18)
        .lineHeight(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(TODAY_CARD_TEXT_PRIMARY)
        .textAlign(TextAlign.Start)
        .width('100%')

      Column({ space: 8 }) {
        if (this.hasPendingReview()) {
          Row({ space: 8 }) {
            Text(`${this.resolvePendingCount()}`)
              .fontSize(46)
              .lineHeight(50)
              .fontWeight(FontWeight.Bold)
              .fontColor(TODAY_CARD_TEXT_PRIMARY)
              .textAlign(TextAlign.Center)

            Text('张待复盘')
              .fontSize(14)
              .lineHeight(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(TODAY_CARD_TEXT_SECONDARY)
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Bottom)
          .width('100%')
        } else {
          Text('已清空')
            .fontSize(27)
            .lineHeight(34)
            .fontWeight(FontWeight.Bold)
            .fontColor(TODAY_CARD_PRIMARY)
            .textAlign(TextAlign.Center)
        }

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
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .padding({ left: 16, right: 16, top: 6, bottom: 6 })
        .borderRadius(12)
        .backgroundColor(this.hasPendingReview() ? TODAY_CARD_PRIMARY : TODAY_CARD_HINT_BACKGROUND)
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .padding(14)
    .borderRadius(18)
    .backgroundColor(TODAY_CARD_BACKGROUND)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
