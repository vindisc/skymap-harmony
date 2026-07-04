const CARD_BACKGROUND: string = '#FFFDF8';
const CARD_TEXT_PRIMARY: string = '#0D1117';
const CARD_TEXT_SECONDARY: string = '#68707A';
const CARD_PRIMARY: string = '#356F80';
const CARD_PRIMARY_SOFT: string = '#D0E8DB';
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

  @Builder
  CompletionBadge() {
    Row({ space: 3 }) {
      Text('完成率')
        .fontSize(10)
        .lineHeight(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(CARD_TEXT_SECONDARY)
        .maxLines(1)

      Text(this.completionRateText)
        .fontSize(14)
        .lineHeight(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(CARD_PRIMARY)
        .maxLines(1)
    }
    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
    .borderRadius(9)
    .backgroundColor('#F0F4F0')
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column({ space: 11 }) {
      Row({ space: 10 }) {
        Text(this.title)
          .fontSize(18)
          .lineHeight(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(CARD_TEXT_PRIMARY)
          .textAlign(TextAlign.Start)
          .layoutWeight(1)
          .maxLines(1)

        this.CompletionBadge()
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Column({ space: 0 }) {
        Text(this.pendingCountText)
          .fontSize(36)
          .lineHeight(40)
          .fontWeight(900)
          .fontColor(CARD_TEXT_PRIMARY)
          .textAlign(TextAlign.Center)
          .letterSpacing(-1)

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

      Text(this.resolveHintText())
        .fontSize(12)
        .lineHeight(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(CARD_PRIMARY)
        .textAlign(TextAlign.Center)
        .width('100%')
        .height(28)
        .borderRadius(14)
        .backgroundColor(CARD_HINT_BACKGROUND)
    }
    .width('100%')
    .height('100%')
    .padding(14)
    .borderRadius(18)
    .backgroundColor(CARD_BACKGROUND)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
