const CARD_BACKGROUND: string = '#FFFFFF';
const CARD_CONTENT_BACKGROUND: string = '#F8F6F1';
const CARD_TEXT_PRIMARY: string = '#0D1117';
const CARD_TEXT_SECONDARY: string = '#68707A';
const CARD_THEME_COLOR: string = '#356F80';

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
    Column({ space: 0 }) {
      // 标题居中 - 紧贴顶部
      Text(this.title)
        .fontSize(15)
        .lineHeight(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(CARD_TEXT_PRIMARY)
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 2, bottom: 4 })

      // 数字区域
      Column({ space: 8 }) {
        // 数字（不带单位）
        Text(this.pendingCountText)
          .fontSize(48)
          .lineHeight(52)
          .fontWeight(900)
          .fontColor(CARD_THEME_COLOR)
          .letterSpacing(-2)
          .textAlign(TextAlign.Center)

        // 辅助说明
        Text('待复盘')
          .fontSize(13)
          .lineHeight(18)
          .fontWeight(FontWeight.Regular)
          .fontColor(CARD_TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .margin({ top: 12 })

      // 占位空间
      Blank()
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
