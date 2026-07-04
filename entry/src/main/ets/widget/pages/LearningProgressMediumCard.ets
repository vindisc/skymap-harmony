const CARD_BACKGROUND: string = '#FFFDF8';
const CARD_TEXT_PRIMARY: string = '#171A1F';
const CARD_TEXT_SECONDARY: string = '#68707A';
const CARD_PRIMARY: string = '#356F80';
const CARD_PRIMARY_SOFT: string = '#DDEFE6';
const CARD_HINT_BACKGROUND: string = '#F1EADF';

let learningProgressCardStorage: LocalStorage = new LocalStorage();

@Entry(learningProgressCardStorage)
@Component
struct LearningProgressMediumCard {
  @LocalStorageProp('title') title: string = '摄影学习';
  @LocalStorageProp('pendingCountText') pendingCountText: string = '0';
  @LocalStorageProp('completionRateText') completionRateText: string = '--';
  @LocalStorageProp('targetRoute') targetRoute: string = 'home';

  private resolveHintText(): string {
    return Number(this.pendingCountText) > 0 ? '点击继续复盘' : '暂无待复盘';
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
    Column({ space: 7 }) {
      Text(this.title)
        .fontSize(18)
        .lineHeight(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(CARD_TEXT_PRIMARY)
        .textAlign(TextAlign.Start)
        .width('100%')

      Column({ space: 0 }) {
        Text(this.pendingCountText)
          .fontSize(40)
          .lineHeight(44)
          .fontWeight(FontWeight.Bold)
          .fontColor(CARD_TEXT_PRIMARY)
          .textAlign(TextAlign.Center)

        Text('待复盘')
          .fontSize(12)
          .lineHeight(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(CARD_TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(66)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(14)
      .backgroundColor(CARD_PRIMARY_SOFT)

      Row() {
        Text('完成率')
          .fontSize(12)
          .lineHeight(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(CARD_TEXT_SECONDARY)

        Blank()

        Text(this.completionRateText)
          .fontSize(15)
          .lineHeight(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(CARD_PRIMARY)
      }
      .width('100%')
      .height(24)
      .padding({ left: 2, right: 2 })

      Text(this.resolveHintText())
        .fontSize(11)
        .lineHeight(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(CARD_TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .width('100%')
        .height(20)
        .borderRadius(10)
        .backgroundColor(CARD_HINT_BACKGROUND)
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .borderRadius(18)
    .backgroundColor(CARD_BACKGROUND)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
