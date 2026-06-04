import { createDefaultReviewContent, ReviewContent } from '../model/ReviewCardModel';
import { AppColors } from './AppDesign';

export class ReviewCardMetrics {
  static readonly shellPadding: number = 14;
  static readonly shellRadius: number = 10;
  static readonly photoRadius: number = 8;
  static readonly infoRadius: number = 8;
  static readonly photoTitleGap: number = 16;
  static readonly titleInfoGap: number = 12;
  static readonly infoGap: number = 10;
  static readonly infoPanelPadding: number = 12;
}

@Component
export struct ReviewTitle {
  @Prop title: string = '';
  @Prop titleSize: number = 20;

  build() {
    Text(this.title.length > 0 ? this.title : '这张照片是否成立')
      .fontSize(this.titleSize)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppColors.text)
      .lineHeight(this.titleSize + 7)
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .width('100%')
  }
}

@Component
export struct ReviewInfoItem {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop bodySize: number = 14;
  @Prop captionSize: number = 11;
  @Prop maxLines: number = 3;
  @Prop compact: boolean = false;

  build() {
    Column() {
      Text(this.label)
        .fontSize(this.captionSize)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.mutedText)
        .lineHeight(this.captionSize + 5)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Text(this.value.length > 0 ? this.value : '待填写')
        .fontSize(this.bodySize)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.value.length > 0 ? AppColors.text : AppColors.mutedText)
        .lineHeight(this.bodySize + 6)
        .maxLines(this.maxLines)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: this.compact ? 4 : 6 })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}

@Component
export struct ReviewInfoGroup {
  @Prop content: ReviewContent = createDefaultReviewContent();
  @Prop bodySize: number = 14;
  @Prop captionSize: number = 11;
  @Prop layout: string = 'column';
  @Prop compact: boolean = false;

  build() {
    if (this.layout === 'row') {
      Column({ space: ReviewCardMetrics.infoGap }) {
        Row({ space: ReviewCardMetrics.infoGap }) {
          ReviewInfoItem({
            label: '第一眼落点',
            value: this.content.firstLook,
            bodySize: this.bodySize,
            captionSize: this.captionSize,
            maxLines: 2,
            compact: this.compact
          })
            .layoutWeight(1)
          ReviewInfoItem({
            label: '是否成立',
            value: this.content.judgement,
            bodySize: this.bodySize,
            captionSize: this.captionSize,
            maxLines: 2,
            compact: this.compact
          })
            .layoutWeight(1)
        }
        .alignItems(VerticalAlign.Top)
        .width('100%')
        ReviewInfoItem({
          label: '卡点',
          value: this.content.blocker,
          bodySize: this.bodySize,
          captionSize: this.captionSize,
          maxLines: 3,
          compact: this.compact
        })
      }
      .padding(ReviewCardMetrics.infoPanelPadding)
      .width('100%')
      .borderRadius(ReviewCardMetrics.infoRadius)
      .backgroundColor('#F8F9FB')
      .border({ width: 1, color: '#E8ECEF' })
    } else {
      Column({ space: ReviewCardMetrics.infoGap }) {
        ReviewInfoItem({
          label: '第一眼落点',
          value: this.content.firstLook,
          bodySize: this.bodySize,
          captionSize: this.captionSize,
          maxLines: this.compact ? 2 : 3,
          compact: this.compact
        })
        ReviewInfoItem({
          label: '是否成立',
          value: this.content.judgement,
          bodySize: this.bodySize,
          captionSize: this.captionSize,
          maxLines: this.compact ? 2 : 3,
          compact: this.compact
        })
        ReviewInfoItem({
          label: '卡点',
          value: this.content.blocker,
          bodySize: this.bodySize,
          captionSize: this.captionSize,
          maxLines: this.compact ? 3 : 4,
          compact: this.compact
        })
      }
      .padding(this.compact ? 10 : ReviewCardMetrics.infoPanelPadding)
      .width('100%')
      .borderRadius(ReviewCardMetrics.infoRadius)
      .backgroundColor('#F8F9FB')
      .border({ width: 1, color: '#E8ECEF' })
    }
  }
}
