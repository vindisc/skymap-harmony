import { WidgetCardBackground } from '../../components/WidgetCardBackground';

const CARD_BACKGROUND: string = '#F8F6F1';
const CARD_TEXT_PRIMARY: string = '#0D1117';
const CARD_TEXT_SECONDARY: string = '#68707A';
const CARD_PRIMARY: string = '#356F80';

// 2*2 左侧小卡片以截图为准：只展示“摄影学习 / 待复盘数量 / 待复盘”。
// 不要再加完成率胶囊、底部按钮或指标底板；改这里时同步更新 verify_learning_progress_widget.mjs。
const LEARNING_CARD_2X2_PADDING: number = 16;
const LEARNING_CARD_2X2_RADIUS: number = 24;
const LEARNING_CARD_2X2_TITLE_SIZE: number = 15;
const LEARNING_CARD_2X2_COUNT_SIZE: number = 48;
const LEARNING_CARD_2X2_COUNT_LINE_HEIGHT: number = 52;

let learningProgressCardStorage: LocalStorage = new LocalStorage();

@Entry(learningProgressCardStorage)
@Component
struct LearningProgressMediumCard {
  @LocalStorageProp('title') title: string = '摄影学习';
  @LocalStorageProp('pendingCountText') pendingCountText: string = '0';
  @LocalStorageProp('cardBackgroundStyle') cardBackgroundStyle: string = 'plain';
  @LocalStorageProp('targetRoute') targetRoute: string = 'home';

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
    Stack() {
      WidgetCardBackground({
        style: this.cardBackgroundStyle,
        baseColor: CARD_BACKGROUND,
        layout: 'square'
      })

      Column({ space: 0 }) {
        Text(this.title)
          .fontSize(LEARNING_CARD_2X2_TITLE_SIZE)
          .lineHeight(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(CARD_TEXT_PRIMARY)
          .textAlign(TextAlign.Center)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 3 })

        Blank()
          .layoutWeight(1)

        Column({ space: 8 }) {
          Text(this.pendingCountText)
            .fontSize(LEARNING_CARD_2X2_COUNT_SIZE)
            .lineHeight(LEARNING_CARD_2X2_COUNT_LINE_HEIGHT)
            .fontWeight(900)
            .fontColor(CARD_PRIMARY)
            .letterSpacing(-2)
            .textAlign(TextAlign.Center)

          Text('待复盘')
            .fontSize(13)
            .lineHeight(18)
            .fontWeight(FontWeight.Regular)
            .fontColor(CARD_TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        Blank()
          .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding(LEARNING_CARD_2X2_PADDING)
    }
    .width('100%')
    .height('100%')
    .borderRadius(LEARNING_CARD_2X2_RADIUS)
    .clip(true)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
