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
    Column({ space: 0 }) {
      // 标题居中
      Text('今日待复盘')
        .fontSize(15)
        .lineHeight(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(TODAY_CARD_TEXT_PRIMARY)
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1)
        .margin({ top: 2, bottom: 4 })

      // 数字区域
      Column({ space: 8 }) {
        // 数字
        Text(`${this.resolvePendingCount()}`)
          .fontSize(48)
          .lineHeight(52)
          .fontWeight(900)
          .fontColor(TODAY_CARD_THEME_COLOR)
          .letterSpacing(-2)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .margin({ top: 12 })

      // 弹性空间
      Blank()
        .layoutWeight(1)

      // 按钮
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
      .padding({ left: 16, right: 16, top: 7, bottom: 7 })
      .borderRadius(12)
      .backgroundColor(this.hasPendingReview() ? TODAY_CARD_THEME_COLOR : '#F1EADF')
      .margin({ bottom: 12 })
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
