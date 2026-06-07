import { createDefaultReviewCardDocument, ReviewCardHistoryItem } from '../model/ReviewCardModel';
import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import { getReviewProjectExcerpt } from '../services/ReviewProjectService';
import { formatReviewTime, getImageRatioLabel, getImageSizeText } from '../utils/ImageLayoutUtils';
import { ReviewPhotoBlock } from './ReviewPhotoBlock';

export class AppColors {
  static readonly pageBackground: string = '#F4F1EC';
  static readonly surface: string = '#FFFEFC';
  static readonly surfaceMuted: string = '#F7F5F1';
  static readonly border: string = '#E5E0D7';
  static readonly text: string = '#171A1F';
  static readonly secondaryText: string = '#5E6470';
  static readonly mutedText: string = '#8A8F98';
  static readonly primary: string = '#1B1E23';
  static readonly primaryPressed: string = '#333840';
  static readonly tagBlue: string = '#EEF4F0';
  static readonly tagBlueText: string = '#496A52';
  static readonly tagGreen: string = '#EAF5ED';
  static readonly tagGreenText: string = '#2E7D5B';
}

export class AppMetrics {
  static readonly pagePadding: number = 20;
  static readonly cardRadius: number = 10;
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
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(32)
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
  @Prop isDisabled: boolean = false;
  onTap: () => void = () => {};

  build() {
    Button(this.label)
      .height(48)
      .width('100%')
      .borderRadius(AppMetrics.buttonRadius)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor('#FFFFFF')
      .backgroundColor(this.isDisabled ? '#B8C6B9' : AppColors.primary)
      .opacity(this.isDisabled ? 0.72 : 1)
      .enabled(!this.isDisabled)
      .stateEffect(!this.isDisabled)
      .onClick(() => {
        if (this.isDisabled) {
          return;
        }
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
      .backgroundColor('#ECE8DF')
      .stateEffect(true)
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
      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(14)
          .fontColor(AppColors.secondaryText)
          .lineHeight(22)
          .margin({ top: 8 })
          .width('100%')
      }
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
  @Prop imageSizeFallbackUsed: boolean = false;

  build() {
    Column({ space: 8 }) {
      Row({ space: 12 }) {
        ReviewPhotoBlock({
          imageUri: this.imageUri,
          imageWidth: this.imageWidth,
          imageHeight: this.imageHeight,
          imageSizeFallbackUsed: this.imageSizeFallbackUsed,
          aspectRatioValue: 1.25,
          compact: true,
          fitMode: ImageFit.Contain
        })
          .width(112)

        Column() {
          Text(getImageRatioLabel(this.imageWidth, this.imageHeight, this.imageSizeFallbackUsed))
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .width('100%')

          if (!this.imageSizeFallbackUsed) {
            Text(getImageSizeText(this.imageWidth, this.imageHeight, this.imageSizeFallbackUsed))
              .fontSize(12)
              .fontColor(AppColors.mutedText)
              .margin({ top: 7 })
              .width('100%')
          }

          if (this.imageSizeFallbackUsed) {
            Text('照片信息暂不可显示，可继续填写。')
              .fontSize(12)
              .fontColor(AppColors.mutedText)
              .lineHeight(18)
              .margin({ top: 7 })
              .width('100%')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')
    }
    .padding(12)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
  }
}

@Component
export struct PhotoWritingHero {
  @Prop imageUri: string = '';
  @Prop imageWidth: number = 1600;
  @Prop imageHeight: number = 1000;
  @Prop imageSizeFallbackUsed: boolean = false;

  build() {
    Column() {
      ReviewPhotoBlock({
        imageUri: this.imageUri,
        imageWidth: this.imageWidth,
        imageHeight: this.imageHeight,
        imageSizeFallbackUsed: this.imageSizeFallbackUsed,
        aspectRatioValue: this.imageWidth > 0 && this.imageHeight > 0 ? this.imageWidth / this.imageHeight : 1,
        fitMode: ImageFit.Contain,
        cornerRadius: 12
      })

      Row({ space: 10 }) {
        Text(getImageRatioLabel(this.imageWidth, this.imageHeight, this.imageSizeFallbackUsed))
          .fontSize(12)
          .fontColor(AppColors.secondaryText)
        Text(getImageSizeText(this.imageWidth, this.imageHeight, this.imageSizeFallbackUsed))
          .fontSize(12)
          .fontColor(AppColors.mutedText)
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
  }
}

@Component
export struct ProjectHomeCard {
  @Prop summary: ReviewProjectSummary = createDefaultProjectSummary();
  onTap: () => void = () => {};

  build() {
    Row({ space: 14 }) {
      if (this.summary.latestItem) {
        Column() {
          ReviewPhotoBlock({
            imageUri: this.summary.latestItem.document.imageUri,
            imageWidth: this.summary.latestItem.document.imageWidth,
            imageHeight: this.summary.latestItem.document.imageHeight,
            imageSizeFallbackUsed: this.summary.latestItem.document.imageSizeFallbackUsed,
            aspectRatioValue: 1,
            compact: true,
            fitMode: ImageFit.Contain,
            cornerRadius: 10
          })
        }
        .width(96)
      } else {
        Column() {
          Text('暂无记录')
            .fontSize(13)
            .fontColor(AppColors.mutedText)
        }
        .justifyContent(FlexAlign.Center)
        .width(96)
        .height(96)
        .borderRadius(10)
        .backgroundColor(AppColors.surfaceMuted)
      }

      Column({ space: 9 }) {
        Text(this.summary.project.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${this.summary.recordCount} 条复盘记录`)
          .fontSize(13)
          .fontColor(AppColors.secondaryText)
          .width('100%')

        Text(this.summary.recordCount > 0 ? `最近更新 ${formatReviewTime(this.summary.latestUpdatedAt)}` : '还没有保存过复盘记录')
          .fontSize(12)
          .fontColor(AppColors.mutedText)
          .width('100%')
          .lineHeight(18)

        if (this.summary.latestItem) {
          Text(this.summary.latestItem.document.content.title.length > 0
            ? this.summary.latestItem.document.content.title
            : '这张照片是否成立')
            .fontSize(13)
            .fontColor(AppColors.text)
            .lineHeight(20)
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .alignItems(VerticalAlign.Center)
    .padding(14)
    .width('100%')
    .borderRadius(12)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
    .onClick(() => {
      this.onTap();
    })
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
        imageSizeFallbackUsed: this.item.document.imageSizeFallbackUsed,
        aspectRatioValue: 1.25,
        compact: true,
        fitMode: ImageFit.Contain
      })
        .width(78)

      Column() {
        Text(this.item.document.content.title.length > 0 ? this.item.document.content.title : '未命名复盘')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Row({ space: 8 }) {
          Text(formatReviewTime(this.item.document.updatedAt))
            .fontSize(12)
            .fontColor(AppColors.secondaryText)
          Text(getImageRatioLabel(
            this.item.document.imageWidth,
            this.item.document.imageHeight,
            this.item.document.imageSizeFallbackUsed
          ))
            .fontSize(12)
            .fontColor(AppColors.mutedText)
        }
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
    .onClick(() => {
      this.onTap();
    })
  }
}

@Component
export struct ProjectReviewCard {
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
        imageSizeFallbackUsed: this.item.document.imageSizeFallbackUsed,
        aspectRatioValue: 1.05,
        compact: true,
        fitMode: ImageFit.Contain,
        cornerRadius: 10
      })
        .width(82)

      Column({ space: 6 }) {
        Text(this.item.document.content.title.length > 0 ? this.item.document.content.title : '未命名复盘')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 8 }) {
          Text(getImageRatioLabel(
            this.item.document.imageWidth,
            this.item.document.imageHeight,
            this.item.document.imageSizeFallbackUsed
          ))
            .fontSize(12)
            .fontColor(AppColors.secondaryText)

          Text(formatReviewTime(this.item.document.updatedAt))
            .fontSize(12)
            .fontColor(AppColors.mutedText)
        }
        .width('100%')

        Text(getReviewProjectExcerpt(this.item.document))
          .fontSize(13)
          .fontColor(AppColors.secondaryText)
          .lineHeight(20)
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Center)
    .padding(12)
    .width('100%')
    .borderRadius(12)
    .backgroundColor(AppColors.surface)
    .border({ width: 1, color: AppColors.border })
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
