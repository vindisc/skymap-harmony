const WIDGET_BACKGROUND_STYLE_HUIWEN: string = 'huiwen';
const WIDGET_BACKGROUND_STYLE_HUIWEN_CORNER: string = 'huiwen_corner';
const WIDGET_BACKGROUND_LAYOUT_WIDE: string = 'wide';

@Component
export struct WidgetCardBackground {
  @Prop style: string = 'plain';
  @Prop baseColor: string = '#F8F6F1';
  @Prop layout: string = 'square';

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.baseColor)

      if (this.style === WIDGET_BACKGROUND_STYLE_HUIWEN) {
        if (this.layout === WIDGET_BACKGROUND_LAYOUT_WIDE) {
          Image($r('app.media.widget_card_huiwen_wide'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        } else {
          Image($r('app.media.widget_card_huiwen_square'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        }
      } else if (this.style === WIDGET_BACKGROUND_STYLE_HUIWEN_CORNER) {
        if (this.layout === WIDGET_BACKGROUND_LAYOUT_WIDE) {
          Image($r('app.media.widget_card_huiwen_corner_wide'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        } else {
          Image($r('app.media.widget_card_huiwen_corner_square'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        }
      }
    }
    .width('100%')
    .height('100%')
    .hitTestBehavior(HitTestMode.None)
  }
}
