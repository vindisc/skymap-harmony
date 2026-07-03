const CARD_BACKGROUND: string = '#FFFDF8';
const CARD_TEXT_PRIMARY: string = '#171A1F';
const CARD_TEXT_SECONDARY: string = '#68707A';
const CARD_PRIMARY: string = '#356F80';
const CARD_PRIMARY_SOFT: string = '#E7F2F6';
const CARD_GREEN: string = '#DDEFE6';
const CARD_BLUE: string = '#E4EEF4';
const CARD_AMBER: string = '#EFE7DB';
const CARD_COMPLETION: string = '#F1EADF';

let learningProgressCardStorage: LocalStorage = new LocalStorage();

@Entry(learningProgressCardStorage)
@Component
struct LearningProgressMediumCard {
  @LocalStorageProp('title') title: string = '摄影学习';
  @LocalStorageProp('pendingCountText') pendingCountText: string = '0';
  @LocalStorageProp('totalImportedCountText') totalImportedCountText: string = '0';
  @LocalStorageProp('completedCountText') completedCountText: string = '0';
  @LocalStorageProp('completionRateText') completionRateText: string = '--';
  @LocalStorageProp('targetRoute') targetRoute: string = 'home';

  @Builder
  MetricTile(label: string, value: string, backgroundColor: string, valueColor: string = CARD_TEXT_PRIMARY) {
    Column({ space: 2 }) {
      Text(value)
        .fontSize(20)
        .lineHeight(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(valueColor)
        .textAlign(TextAlign.Center)

      Text(label)
        .fontSize(10)
        .lineHeight(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(CARD_TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
    .height(46)
    .padding({ left: 6, right: 6 })
    .borderRadius(10)
    .backgroundColor(backgroundColor)
  }

  build() {
    FormLink({
      action: 'router',
      abilityName: 'EntryAbility',
      params: {
        targetRoute: this.targetRoute
      }
    }) {
      Column({ space: 8 }) {
        Text(this.title)
          .fontSize(18)
          .lineHeight(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(CARD_TEXT_PRIMARY)
          .textAlign(TextAlign.Start)
          .width('100%')

        Column({ space: 8 }) {
          Row({ space: 8 }) {
            this.MetricTile('待复盘', this.pendingCountText, CARD_GREEN)
            this.MetricTile('累计导入', this.totalImportedCountText, CARD_BLUE)
          }
          .width('100%')

          Row({ space: 8 }) {
            this.MetricTile('已完成', this.completedCountText, CARD_AMBER)
            this.MetricTile('完成率', this.completionRateText, CARD_COMPLETION, CARD_PRIMARY)
          }
          .width('100%')
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .height('100%')
      .padding(12)
      .borderRadius(18)
      .backgroundColor(CARD_BACKGROUND)
    }
    .width('100%')
    .height('100%')
  }
}
