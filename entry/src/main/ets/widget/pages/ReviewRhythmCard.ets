const RHYTHM_CARD_BACKGROUND: string = '#F8F6F1';
const RHYTHM_CARD_ACCENT: string = '#356F80';
const RHYTHM_CARD_TEXT_PRIMARY: string = '#0D1117';
const RHYTHM_CARD_TEXT_SECONDARY: string = '#68707A';
const RHYTHM_CARD_ACTION_DISABLED: string = '#F1EADF';
const RHYTHM_REVIEW_DIRECT_TARGET_ROUTE: string = 'today_review_direct';
const RHYTHM_CARD_BACKGROUND_STYLE_TEXTURE: string = 'texture';
const RHYTHM_CARD_TEXTURE_OPACITY: number = 0.36;

const RHYTHM_CARD_PADDING: number = 16;
const RHYTHM_CARD_RADIUS: number = 24;
const RHYTHM_CARD_TITLE_SIZE: number = 15;
const RHYTHM_CARD_DAY_SIZE: number = 54;
const RHYTHM_CARD_DAY_LINE_HEIGHT: number = 58;
const RHYTHM_CARD_DAY_UNIT_SIZE: number = 18;
const RHYTHM_CARD_DAY_UNIT_LINE_HEIGHT: number = 24;
const RHYTHM_CARD_ACTION_HEIGHT: number = 32;
const RHYTHM_CARD_ACTION_RADIUS: number = 13;

let reviewRhythmCardStorage: LocalStorage = new LocalStorage();

@Entry(reviewRhythmCardStorage)
@Component
struct ReviewRhythmCard {
  @LocalStorageProp('reviewStreakDaysText') reviewStreakDaysText: string = '3';
  @LocalStorageProp('pendingCountText') pendingCountText: string = '0';
  @LocalStorageProp('cardBackgroundStyle') cardBackgroundStyle: string = 'plain';
  @LocalStorageProp('targetRoute') targetRoute: string = 'home';

  private useTextureBackground(): boolean {
    return this.cardBackgroundStyle === RHYTHM_CARD_BACKGROUND_STYLE_TEXTURE;
  }

  private resolveStreakDays(): number {
    const count: number = Number(this.reviewStreakDaysText);
    return Number.isNaN(count) ? 0 : Math.max(0, count);
  }

  private hasPendingReview(): boolean {
    return Number(this.pendingCountText) > 0;
  }

  private openTargetRoute(): void {
    postCardAction(this, {
      action: 'router',
      moduleName: 'entry',
      abilityName: 'EntryAbility',
      params: {
        targetRoute: this.hasPendingReview() ? RHYTHM_REVIEW_DIRECT_TARGET_ROUTE : this.targetRoute
      }
    });
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(RHYTHM_CARD_BACKGROUND)

      if (this.useTextureBackground()) {
        Image($r('app.media.widget_card_texture'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .opacity(RHYTHM_CARD_TEXTURE_OPACITY)
      }

      Column({ space: 0 }) {
        Text('连续复盘')
          .fontSize(RHYTHM_CARD_TITLE_SIZE)
          .lineHeight(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(RHYTHM_CARD_TEXT_PRIMARY)
          .textAlign(TextAlign.Center)
          .width('100%')
          .maxLines(1)
          .margin({ top: 2 })

        Blank()
          .layoutWeight(1)

        Row({ space: 7 }) {
          Text(`${this.resolveStreakDays()}`)
            .fontSize(RHYTHM_CARD_DAY_SIZE)
            .lineHeight(RHYTHM_CARD_DAY_LINE_HEIGHT)
            .fontWeight(900)
            .fontColor(RHYTHM_CARD_ACCENT)
            .letterSpacing(-2)

          Text('天')
            .fontSize(RHYTHM_CARD_DAY_UNIT_SIZE)
            .lineHeight(RHYTHM_CARD_DAY_UNIT_LINE_HEIGHT)
            .fontWeight(FontWeight.Bold)
            .fontColor(RHYTHM_CARD_TEXT_PRIMARY)
            .maxLines(1)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)

        Blank()
          .layoutWeight(1)

        Row({ space: 6 }) {
          Text('去复盘')
            .fontSize(13)
            .lineHeight(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.hasPendingReview() ? '#FFFDF8' : RHYTHM_CARD_TEXT_SECONDARY)
            .maxLines(1)

          Text('→')
            .fontSize(15)
            .lineHeight(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.hasPendingReview() ? '#FFFDF8' : RHYTHM_CARD_TEXT_SECONDARY)
            .maxLines(1)
        }
        .width('100%')
        .height(RHYTHM_CARD_ACTION_HEIGHT)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .borderRadius(RHYTHM_CARD_ACTION_RADIUS)
        .backgroundColor(this.hasPendingReview() ? RHYTHM_CARD_ACCENT : RHYTHM_CARD_ACTION_DISABLED)
      }
      .width('100%')
      .height('100%')
      .padding(RHYTHM_CARD_PADDING)
    }
    .width('100%')
    .height('100%')
    .borderRadius(RHYTHM_CARD_RADIUS)
    .clip(true)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
