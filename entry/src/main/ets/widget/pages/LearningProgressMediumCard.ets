const CARD_BACKGROUND: string = '#FFFFFF';
const CARD_CONTENT_BACKGROUND: string = '#F8F6F1';
const CARD_TEXT_PRIMARY: string = '#0D1117';
const CARD_TEXT_SECONDARY: string = '#68707A';
const CARD_THEME_COLOR: string = '#356F80';
const CARD_THEME_SOFT: string = '#D8EDE5';

// 圆角
const LEARNING_CARD_OUTER_RADIUS: number = 24;
const LEARNING_CARD_PADDING: number = 16;

let learningProgressCardStorage: LocalStorage = new LocalStorage();

@Entry(learningProgressCardStorage)
@Component
struct LearningProgressMediumCard {
  @LocalStorageProp('title') title: string = '摄影学习';
  @LocalStorageProp('pendingCountText') pendingCountText: string = '0';
  @LocalStorageProp('completionRateText') completionRateText: string = '--';
  @LocalStorageProp('targetRoute') targetRoute: string = 'home';

  private hasPendingReview(): boolean {
    return Number(this.pendingCountText) > 0;
  }

  private resolveHintText(): string {
    return this.hasPendingReview() ? '继续复盘' : '暂无待复盘';
  }

  @Builder
  CompletionBadge() {
    Row({ space: 4 }) {
      Text('完成')
        .fontSize(12)
        .lineHeight(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(CARD_TEXT_SECONDARY)

      Text(this.completionRateText)
        .fontSize(16)
        .lineHeight(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(CARD_THEME_COLOR)
    }
    .padding(14)
    .borderRadius(12)
    .backgroundColor(CARD_THEME_SOFT)
  }

  private openTargetRoute(): void {
    postCardAction(this, {
      action: 'router',
      moduleName: 'entry',
      abilityName: 'EntryAbility',
      params: {
        targetRoute: this.targetRoute
      }
    });
  }

  build() {
    Column({ space: 11 }) {
      Text(this.title)
        .fontSize(16)
        .lineHeight(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(CARD_TEXT_PRIMARY)
        .textAlign(TextAlign.Start)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      this.CompletionBadge()

      Column({ space: 8 }) {
        Text(this.pendingCountText)
          .fontSize(36)
          .lineHeight(40)
          .fontWeight(900)
          .fontColor(CARD_THEME_COLOR)
          .letterSpacing(-1)
          .textAlign(TextAlign.Start)
          .width('100%')

        Text('待复盘')
          .fontSize(13)
          .lineHeight(18)
          .fontWeight(FontWeight.Regular)
          .fontColor(CARD_TEXT_SECONDARY)
          .textAlign(TextAlign.Start)
          .width('100%')

        Row({ space: 6 }) {
          Text(this.resolveHintText())
            .fontSize(13)
            .lineHeight(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.hasPendingReview() ? '#FFFDF8' : CARD_TEXT_SECONDARY)

          Text('→')
            .fontSize(15)
            .lineHeight(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.hasPendingReview() ? '#FFFDF8' : CARD_TEXT_SECONDARY)
        }
        .height(30)
        .padding(14)
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(this.hasPendingReview() ? CARD_THEME_COLOR : '#F1EADF')
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(LEARNING_CARD_PADDING)
    .borderRadius(LEARNING_CARD_OUTER_RADIUS)
    .backgroundColor(CARD_CONTENT_BACKGROUND)
    .justifyContent(FlexAlign.Start)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
