const TODAY_CARD_BACKGROUND: string = '#FFFDF8';
const TODAY_CARD_TEXT_PRIMARY: string = '#171A1F';
const TODAY_CARD_TEXT_SECONDARY: string = '#68707A';
const TODAY_CARD_PRIMARY: string = '#356F80';
const TODAY_CARD_HINT_BACKGROUND: string = '#F1EADF';
const TODAY_REVIEW_DIRECT_TARGET_ROUTE: string = 'today_review_direct';

// 今日复盘 2*2 小卡片必须让内容区接管剩余高度，避免底部按钮被桌面裁切。
// 不要回退成“数字和按钮顺序平铺”的贴底版；改这里时同步更新 verify_learning_progress_widget.mjs。
const TODAY_CARD_2X2_PADDING: number = 14;
const TODAY_CARD_2X2_RADIUS: number = 18;
const TODAY_CARD_2X2_COLUMN_GAP: number = 14;
const TODAY_CARD_2X2_TITLE_SIZE: number = 18;
const TODAY_CARD_2X2_ACTION_VERTICAL_PADDING: number = 6;

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
    Column({ space: TODAY_CARD_2X2_COLUMN_GAP }) {
      Text('今日复盘')
        .fontSize(TODAY_CARD_2X2_TITLE_SIZE)
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
        .padding({
          left: 16,
          right: 16,
          top: TODAY_CARD_2X2_ACTION_VERTICAL_PADDING,
          bottom: TODAY_CARD_2X2_ACTION_VERTICAL_PADDING
        })
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
    .padding(TODAY_CARD_2X2_PADDING)
    .borderRadius(TODAY_CARD_2X2_RADIUS)
    .backgroundColor(TODAY_CARD_BACKGROUND)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
