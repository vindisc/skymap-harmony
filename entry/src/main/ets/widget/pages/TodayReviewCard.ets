const TODAY_CARD_BACKGROUND: string = '#F8F6F1';
const TODAY_CARD_TEXT_PRIMARY: string = '#0D1117';
const TODAY_CARD_TEXT_SECONDARY: string = '#68707A';
const TODAY_CARD_PRIMARY: string = '#356F80';
const TODAY_CARD_ACTION_DISABLED: string = '#F1EADF';
const TODAY_REVIEW_DIRECT_TARGET_ROUTE: string = 'today_review_direct';
const TODAY_CARD_BACKGROUND_STYLE_TEXTURE: string = 'texture';
const TODAY_CARD_TEXTURE_OPACITY: number = 0.36;

// 2*2 右侧小卡片以截图为准：标题为“今日待复盘”，中间大数字，底部保留可见按钮。
// 不要回退成“张待复盘”说明文案或按钮贴底裁切结构；改这里时同步更新 verify_learning_progress_widget.mjs。
const TODAY_CARD_2X2_PADDING: number = 16;
const TODAY_CARD_2X2_RADIUS: number = 24;
const TODAY_CARD_2X2_TITLE_SIZE: number = 15;
const TODAY_CARD_2X2_COUNT_SIZE: number = 48;
const TODAY_CARD_2X2_COUNT_LINE_HEIGHT: number = 52;
const TODAY_CARD_2X2_ACTION_WIDTH: number = 116;
const TODAY_CARD_2X2_ACTION_HEIGHT: number = 32;
const TODAY_CARD_2X2_ACTION_RADIUS: number = 13;

let todayReviewCardStorage: LocalStorage = new LocalStorage();

@Entry(todayReviewCardStorage)
@Component
struct TodayReviewCard {
  @LocalStorageProp('pendingCountText') pendingCountText: string = '0';
  @LocalStorageProp('cardBackgroundStyle') cardBackgroundStyle: string = 'plain';
  @LocalStorageProp('targetRoute') targetRoute: string = 'home';

  private useTextureBackground(): boolean {
    return this.cardBackgroundStyle === TODAY_CARD_BACKGROUND_STYLE_TEXTURE;
  }

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
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(TODAY_CARD_BACKGROUND)

      if (this.useTextureBackground()) {
        Image($r('app.media.widget_card_texture'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .opacity(TODAY_CARD_TEXTURE_OPACITY)
      }

      Column({ space: 0 }) {
        Text('今日待复盘')
          .fontSize(TODAY_CARD_2X2_TITLE_SIZE)
          .lineHeight(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(TODAY_CARD_TEXT_PRIMARY)
          .textAlign(TextAlign.Center)
          .width('100%')
          .maxLines(1)
          .margin({ top: 3 })

        Blank()
          .layoutWeight(1)

        Text(`${this.resolvePendingCount()}`)
          .fontSize(TODAY_CARD_2X2_COUNT_SIZE)
          .lineHeight(TODAY_CARD_2X2_COUNT_LINE_HEIGHT)
          .fontWeight(900)
          .fontColor(TODAY_CARD_PRIMARY)
          .letterSpacing(-2)
          .textAlign(TextAlign.Center)

        Blank()
          .layoutWeight(1)

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
        .width(TODAY_CARD_2X2_ACTION_WIDTH)
        .height(TODAY_CARD_2X2_ACTION_HEIGHT)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .borderRadius(TODAY_CARD_2X2_ACTION_RADIUS)
        .backgroundColor(this.hasPendingReview() ? TODAY_CARD_PRIMARY : TODAY_CARD_ACTION_DISABLED)
      }
      .width('100%')
      .height('100%')
      .padding(TODAY_CARD_2X2_PADDING)
    }
    .width('100%')
    .height('100%')
    .borderRadius(TODAY_CARD_2X2_RADIUS)
    .clip(true)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
