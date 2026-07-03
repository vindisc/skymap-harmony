const CARD_BACKGROUND: string = '#FFFDF8';
const CARD_TEXT_PRIMARY: string = '#171A1F';
const CARD_TEXT_SECONDARY: string = '#68707A';
const CARD_PRIMARY: string = '#356F80';
const CARD_PRIMARY_SOFT: string = '#E7F2F6';
const CARD_GREEN: string = '#DDEFE6';
const CARD_BLUE: string = '#E4EEF4';
const CARD_AMBER: string = '#EFE7DB';

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
  StatRow(label: string, value: string, backgroundColor: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(CARD_TEXT_SECONDARY)

      Blank()

      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(CARD_TEXT_PRIMARY)
    }
    .width('100%')
    .height(36)
    .padding({ left: 14, right: 14 })
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
      Column({ space: 10 }) {
        Row() {
          Text(this.title)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(CARD_TEXT_PRIMARY)

          Blank()

          Text(`完成率 ${this.completionRateText}`)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(CARD_PRIMARY)
            .height(26)
            .padding({ left: 10, right: 10 })
            .borderRadius(13)
            .backgroundColor(CARD_PRIMARY_SOFT)
        }
        .width('100%')

        Column({ space: 8 }) {
          this.StatRow('待复盘', this.pendingCountText, CARD_GREEN)
          this.StatRow('累计导入', this.totalImportedCountText, CARD_BLUE)
          this.StatRow('已完成', this.completedCountText, CARD_AMBER)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .padding(16)
      .borderRadius(18)
      .backgroundColor(CARD_BACKGROUND)
    }
    .width('100%')
    .height('100%')
  }
}
