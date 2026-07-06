const CARD_BACKGROUND: string = '#FFFDF8';
const CARD_TEXT_PRIMARY: string = '#0D1117';
const CARD_TEXT_SECONDARY: string = '#68707A';
const CARD_PRIMARY: string = '#356F80';
const CARD_PRIMARY_SOFT: string = '#D0E8DB';
const CARD_HINT_BACKGROUND: string = '#F1EADF';

// 2*2 小卡片要同时保留“完成率胶囊 + 待复盘指标块 + 底部操作”三段式结构。
// 不要回退成大数字贴底版；改这里时同步更新 verify_learning_progress_widget.mjs。
const LEARNING_CARD_2X2_PADDING: number = 14;
const LEARNING_CARD_2X2_RADIUS: number = 18;
const LEARNING_CARD_2X2_COLUMN_GAP: number = 11;
const LEARNING_CARD_2X2_TITLE_SIZE: number = 16;
const LEARNING_CARD_2X2_METRIC_HEIGHT: number = 66;
const LEARNING_CARD_2X2_ACTION_HEIGHT: number = 30;

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
    Row({ space: 2 }) {
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
    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
    .borderRadius(8)
    .backgroundColor('#F0F4F0')
    .alignItems(VerticalAlign.Center)
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
    Column({ space: LEARNING_CARD_2X2_COLUMN_GAP }) {
      Row({ space: 8 }) {
        Text(this.title)
          .fontSize(LEARNING_CARD_2X2_TITLE_SIZE)
          .lineHeight(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(CARD_TEXT_PRIMARY)
          .textAlign(TextAlign.Start)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

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
      .height(LEARNING_CARD_2X2_METRIC_HEIGHT)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(14)
      .backgroundColor(CARD_PRIMARY_SOFT)

      Row({ space: 6 }) {
        Text(this.resolveHintText())
          .fontSize(13)
          .lineHeight(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.hasPendingReview() ? '#FFFDF8' : CARD_TEXT_SECONDARY)
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
      .width('100%')
      .height(LEARNING_CARD_2X2_ACTION_HEIGHT)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .borderRadius(12)
      .backgroundColor(this.hasPendingReview() ? CARD_PRIMARY : CARD_HINT_BACKGROUND)
    }
    .width('100%')
    .height('100%')
    .padding(LEARNING_CARD_2X2_PADDING)
    .borderRadius(LEARNING_CARD_2X2_RADIUS)
    .backgroundColor(CARD_BACKGROUND)
    .onClick(() => {
      this.openTargetRoute();
    })
  }
}
