import { createDefaultReviewCardDocument, ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { formatReviewTime, getImageRatioLabel } from '../utils/ImageLayoutUtils';
import { ReviewPhotoBlock } from './ReviewPhotoBlock';

export class AppColors {
  static readonly pageBackground: string = '#F5F6F8';
  static readonly surface: string = '#FFFFFF';
  static readonly surfaceMuted: string = '#F8F9FB';
  static readonly border: string = '#E6E9ED';
  static readonly text: string = '#171A1F';
  static readonly secondaryText: string = '#5F6673';
  static readonly mutedText: string = '#8A919F';
  static readonly primary: string = '#111827';
  static readonly primaryPressed: string = '#2B313C';
  static readonly tagBlue: string = '#EAF2FF';
  static readonly tagBlueText: string = '#2563EB';
  static readonly tagGreen: string = '#E9F6F0';
  static readonly tagGreenText: string = '#2E7D5B';
}

export class AppMetrics {
  static readonly pagePadding: number = 20;
  static readonly cardRadius: number = 8;
  static readonly buttonRadius: number = 7;
  static readonly panelRadius: number = 8;
}

@Component
export struct AppPageHeader {
  @Prop title: string = '';
  @Prop subtitle: string = '';

  build() {
    Column() {
      Text(this.title)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(34)
        .width('100%')
      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(15)
          .fontColor(AppColors.secondaryText)
          .lineHeight(23)
          .margin({ top: 8 })
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}

@Component
export struct PrimaryButton {
  @Prop label: string = '';
  onTap: () => void = () => {};

  build() {
    Button(this.label)
      .height(52)
      .width('100%')
      .borderRadius(AppMetrics.buttonRadius)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor('#FFFFFF')
      .backgroundColor(AppColors.primary)
      .onClick(() => {
        this.onTap();
      })
  }
}

@Component
export struct SecondaryButton {
  @Prop label: string = '';
  onTap: () => void = () => {};

  build() {
    Button(this.label)
      .height(44)
      .width('100%')
      .borderRadius(AppMetrics.buttonRadius)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.text)
      .backgroundColor('#EEF1F4')
      .onClick(() => {
        this.onTap();
      })
  }
}

@Component
export struct EmptyState {
  @Prop title: string = '';
  @Prop message: string = '';

  build() {
    Column() {
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
        .width('100%')
      Text(this.message)
        .fontSize(14)
        .fontColor(AppColors.secondaryText)
        .lineHeight(22)
        .margin({ top: 8 })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(18)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }
}

@Component
export struct TagLabel {
  @Prop label: string = '';
  @Prop color: string = AppColors.tagBlueText;
  @Prop tagBackground: string = AppColors.tagBlue;

  build() {
    Text(this.label)
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.color)
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .borderRadius(4)
      .backgroundColor(this.tagBackground)
  }
}

@Component
export struct PhotoSummaryCard {
  @Prop imageUri: string = '';
  @Prop imageWidth: number = 1600;
  @Prop imageHeight: number = 1000;

  build() {
    Row({ space: 12 }) {
      ReviewPhotoBlock({
        imageUri: this.imageUri,
        imageWidth: this.imageWidth,
        imageHeight: this.imageHeight,
        aspectRatioValue: 1.25,
        compact: true
      })
        .width(112)

      Column() {
        Row({ space: 8 }) {
          TagLabel({ label: getImageRatioLabel(this.imageWidth, this.imageHeight) })
          Text(`${this.imageWidth} x ${this.imageHeight}`)
            .fontSize(12)
            .fontColor(AppColors.mutedText)
        }
        .width('100%')

        Text('照片方向会自动匹配复盘卡版式')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .lineHeight(21)
          .margin({ top: 10 })
          .width('100%')

        Text('保留真实照片作为视觉主体，文字只记录关键判断。')
          .fontSize(12)
          .fontColor(AppColors.secondaryText)
          .lineHeight(18)
          .margin({ top: 6 })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Center)
    .padding(12)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }
}

@Component
export struct RecentReviewCard {
  @Prop item: ReviewCardHistoryItem = {
    document: createDefaultReviewCardDocument(),
    exportedPath: ''
  };
  onTap: () => void = () => {};

  build() {
    Row({ space: 12 }) {
      ReviewPhotoBlock({
        imageUri: this.item.document.imageUri,
        imageWidth: this.item.document.imageWidth,
        imageHeight: this.item.document.imageHeight,
        aspectRatioValue: 1.25,
        compact: true
      })
        .width(92)

      Column() {
        Text(this.item.document.content.title.length > 0 ? this.item.document.content.title : '未命名复盘')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row({ space: 7 }) {
          TagLabel({ label: getImageRatioLabel(this.item.document.imageWidth, this.item.document.imageHeight) })
          Text(formatReviewTime(this.item.document.updatedAt))
            .fontSize(12)
            .fontColor(AppColors.secondaryText)
          if (this.item.exportedPath.length > 0) {
            TagLabel({ label: '已导出', color: AppColors.tagGreenText, tagBackground: AppColors.tagGreen })
          } else {
            TagLabel({ label: '已保存', color: AppColors.secondaryText, tagBackground: '#F1F3F5' })
          }
        }
        .margin({ top: 8 })
        .width('100%')

        Text('查看成品卡')
          .fontSize(12)
          .fontColor(AppColors.mutedText)
          .margin({ top: 9 })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Center)
    .padding(12)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
    .shadow({ radius: 10, color: '#0D000000', offsetX: 0, offsetY: 4 })
    .onClick(() => {
      this.onTap();
    })
  }
}

@Component
export struct InfoBlockCard {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop bodySize: number = 14;
  @Prop captionSize: number = 11;
  @Prop maxLines: number = 4;

  build() {
    Column() {
      Text(this.label)
        .fontSize(this.captionSize)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.mutedText)
        .width('100%')
      Text(this.value.length > 0 ? this.value : '待填写')
        .fontSize(this.bodySize)
        .fontColor(AppColors.text)
        .lineHeight(this.bodySize + 6)
        .maxLines(this.maxLines)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(13)
    .width('100%')
    .borderRadius(AppMetrics.panelRadius)
    .backgroundColor(AppColors.surfaceMuted)
    .border({ width: 1, color: AppColors.border })
  }
}
