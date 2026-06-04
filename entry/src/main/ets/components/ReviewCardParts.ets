import { createDefaultReviewContent, ReviewContent } from '../model/ReviewCardModel';
import { AppColors } from './AppDesign';

export class ReviewCardMetrics {
  static readonly shellPadding: number = 14;
  static readonly contentInset: number = 16;
  static readonly shellRadius: number = 10;
  static readonly photoRadius: number = 8;
  static readonly infoRadius: number = 6;
  static readonly photoTitleGap: number = 14;
  static readonly titleInfoGap: number = 12;
  static readonly infoGap: number = 8;
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
        .fontWeight(FontWeight.Regular)
        .fontColor(AppColors.mutedText)
        .lineHeight(this.captionSize + 5)
        .width('100%')
      Text(this.value.length > 0 ? this.value : '待填写')
        .fontSize(this.bodySize)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.value.length > 0 ? AppColors.text : AppColors.mutedText)
        .lineHeight(this.bodySize + 5)
        .maxLines(this.maxLines)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: this.compact ? 4 : 5 })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      left: this.compact ? 9 : 11,
      right: this.compact ? 9 : 11,
      top: this.compact ? 8 : 10,
      bottom: this.compact ? 8 : 10
    })
    .width('100%')
    .borderRadius(ReviewCardMetrics.infoRadius)
    .backgroundColor('#F8FAFB')
    .border({ width: 1, color: '#E8ECEF' })
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
      Row({ space: ReviewCardMetrics.infoGap }) {
        ReviewInfoItem({
          label: '第一眼落点',
          value: this.content.firstLook,
          bodySize: this.bodySize,
          captionSize: this.captionSize,
          maxLines: 3,
          compact: this.compact
        })
          .layoutWeight(1)
        ReviewInfoItem({
          label: '是否成立',
          value: this.content.judgement,
          bodySize: this.bodySize,
          captionSize: this.captionSize,
          maxLines: 3,
          compact: this.compact
        })
          .layoutWeight(1)
        ReviewInfoItem({
          label: '卡点',
          value: this.content.blocker,
          bodySize: this.bodySize,
          captionSize: this.captionSize,
          maxLines: 4,
          compact: this.compact
        })
          .layoutWeight(1)
      }
      .alignItems(VerticalAlign.Top)
      .width('100%')
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
      .width('100%')
    }
  }
}
