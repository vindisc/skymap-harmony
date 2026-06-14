import {
  createDefaultReviewCardDocument,
  normalizeReviewJudgement,
  ReviewCardHistoryItem,
  ReviewJudgementStatus
} from '../model/ReviewCardModel';
import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import { getReviewProjectExcerpt } from '../services/ReviewProjectService';
import { formatReviewTime, getImageRatioLabel, getImageSizeText, hasDisplayableImageUri } from '../utils/ImageLayoutUtils';
import { ReviewPhotoBlock } from './ReviewPhotoBlock';

export class AppColors {
  static readonly pageBackground: string = '#F7F6F3';
  static readonly surface: string = '#FFFEFC';
  static readonly surfaceMuted: string = '#F1EFE9';
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
  static readonly space8: number = 8;
  static readonly space16: number = 16;
  static readonly space24: number = 24;
  static readonly space32: number = 32;
  static readonly space48: number = 48;
  static readonly pagePadding: number = 24;
  static readonly pageTopPadding: number = 24;
  static readonly cardRadius: number = 8;
  static readonly buttonRadius: number = 8;
  static readonly capsuleRadius: number = 16;
  static readonly panelRadius: number = 8;
  static readonly controlHeight: number = 48;
  static readonly compactControlHeight: number = 40;
  static readonly chipHeight: number = 40;
  static readonly tabBarItemHeight: number = 56;
}

export class AppTypography {
  static readonly level1: number = 48;
  static readonly level1LineHeight: number = 56;
  static readonly level2: number = 32;
  static readonly level2LineHeight: number = 40;
  static readonly level3: number = 26;
  static readonly level3LineHeight: number = 34;
  static readonly body: number = 20;
  static readonly bodyLineHeight: number = 28;
  static readonly auxiliary: number = 16;
  static readonly auxiliaryLineHeight: number = 24;
  static readonly caption: number = 16;
  static readonly captionLineHeight: number = 24;
}

@Component
export struct AppPageHeader {
  @Prop title: string = '';
  @Prop subtitle: string = '';

  build() {
    Column() {
      Text(this.title)
        .fontSize(AppTypography.level1)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.level1LineHeight)
        .width('100%')
      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(AppTypography.body)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.bodyLineHeight)
          .margin({ top: AppMetrics.space8 })
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
      .height(AppMetrics.controlHeight)
      .width('100%')
      .borderRadius(AppMetrics.buttonRadius)
      .fontSize(AppTypography.body)
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
      .height(AppMetrics.compactControlHeight)
      .width('100%')
      .borderRadius(AppMetrics.capsuleRadius)
      .fontSize(AppTypography.auxiliary)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.text)
      .backgroundColor(AppColors.surfaceMuted)
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
        .fontSize(AppTypography.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
        .width('100%')
      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(AppTypography.auxiliary)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.auxiliaryLineHeight)
          .margin({ top: AppMetrics.space8 })
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding(AppMetrics.space16)
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
      .fontSize(AppTypography.caption)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.color)
      .padding({ left: AppMetrics.space8, right: AppMetrics.space8, top: AppMetrics.space8, bottom: AppMetrics.space8 })
      .borderRadius(AppMetrics.cardRadius)
      .backgroundColor(this.tagBackground)
  }
}

function getJudgementBadgeText(value: string): string {
  const judgement: ReviewJudgementStatus = normalizeReviewJudgement(value);
  if (judgement === ReviewJudgementStatus.VALID) {
    return '✓ 成立';
  }
  if (judgement === ReviewJudgementStatus.INVALID) {
    return '✕ 不成立';
  }
  return '待判断？';
}

function getJudgementBadgeColor(value: string): string {
  const judgement: ReviewJudgementStatus = normalizeReviewJudgement(value);
  if (judgement === ReviewJudgementStatus.VALID) {
    return '#6B7A70';
  }
  if (judgement === ReviewJudgementStatus.INVALID) {
    return '#866B66';
  }
  return '#7B7568';
}

function getJudgementBadgeBackground(_value: string): string {
  return '#F3F0EA';
}

@Component
export struct ReviewJudgementBadge {
  @Prop value: string = ReviewJudgementStatus.UNSURE;

  build() {
    Text(getJudgementBadgeText(this.value))
      .fontSize(AppTypography.caption)
      .fontWeight(FontWeight.Regular)
      .fontColor(getJudgementBadgeColor(this.value))
      .padding({ left: AppMetrics.space8, right: AppMetrics.space8, top: AppMetrics.space8, bottom: AppMetrics.space8 })
      .borderRadius(AppMetrics.cardRadius)
      .backgroundColor(getJudgementBadgeBackground(this.value))
      .textAlign(TextAlign.Center)
      .maxLines(1)
      .opacity(0.78)
  }
}

@Component
export struct PhotoSummaryCard {
  @Prop imageUri: string = '';
  @Prop imageWidth: number = 1600;
  @Prop imageHeight: number = 1000;
  @Prop imageSizeFallbackUsed: boolean = false;

  build() {
    Column({ space: AppMetrics.space8 }) {
      Row({ space: AppMetrics.space16 }) {
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
            .fontSize(AppTypography.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .width('100%')

          if (!this.imageSizeFallbackUsed) {
            Text(getImageSizeText(this.imageWidth, this.imageHeight, this.imageSizeFallbackUsed))
              .fontSize(AppTypography.caption)
              .fontColor(AppColors.mutedText)
              .margin({ top: AppMetrics.space8 })
              .width('100%')
          }

          if (this.imageSizeFallbackUsed) {
            Text('照片信息暂不可显示，可继续填写。')
              .fontSize(AppTypography.caption)
              .fontColor(AppColors.mutedText)
              .lineHeight(AppTypography.captionLineHeight)
              .margin({ top: AppMetrics.space8 })
              .width('100%')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')
    }
    .padding(AppMetrics.space16)
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
  @Prop fixedFrame: boolean = false;
  @State loadFailed: boolean = false;

  private getAspectRatioValue(): number {
    if (this.imageWidth > 0 && this.imageHeight > 0) {
      return this.imageWidth / this.imageHeight;
    }
    return 1;
  }

  @Builder
  Placeholder() {
    Column() {
      Text(hasDisplayableImageUri(this.imageUri) && this.loadFailed ? '图片加载失败' : '照片预览')
        .fontSize(AppTypography.auxiliary)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.text)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor('#E9E5DC')
  }

  build() {
    if (this.fixedFrame) {
      Stack({ alignContent: Alignment.Center }) {
        if (hasDisplayableImageUri(this.imageUri) && !this.loadFailed) {
          Image(this.imageUri)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .syncLoad(true)
            .onError(() => {
              this.loadFailed = true;
            })
        } else {
          this.Placeholder()
        }
      }
        .width('100%')
        .height('100%')
        .alignSelf(ItemAlign.Center)
        .backgroundColor(AppColors.pageBackground)
    } else {
      Stack() {
        if (hasDisplayableImageUri(this.imageUri) && !this.loadFailed) {
          Image(this.imageUri)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .syncLoad(true)
            .onError(() => {
              this.loadFailed = true;
            })
        } else {
          this.Placeholder()
        }
      }
        .width('94%')
        .aspectRatio(this.getAspectRatioValue())
        .alignSelf(ItemAlign.Center)
        .borderRadius(AppMetrics.cardRadius)
        .clip(true)
        .backgroundColor('#E9E5DC')
        .border({ width: 1, color: AppColors.border })
    }
  }
}

@Component
export struct ProjectHomeCard {
  @Prop summary: ReviewProjectSummary = createDefaultProjectSummary();
  onTap: () => void = () => {};

  @Builder
  CoverTile(index: number) {
    if (index < this.summary.items.length) {
      ReviewPhotoBlock({
        imageUri: this.summary.items[index].document.imageUri,
        imageWidth: this.summary.items[index].document.imageWidth,
        imageHeight: this.summary.items[index].document.imageHeight,
        imageSizeFallbackUsed: this.summary.items[index].document.imageSizeFallbackUsed,
        aspectRatioValue: 1,
        compact: true,
        fitMode: ImageFit.Cover,
        cornerRadius: 3
      })
        .width(AppMetrics.controlHeight)
    } else {
      Column()
        .width(AppMetrics.controlHeight)
        .height(AppMetrics.controlHeight)
        .backgroundColor(AppColors.surfaceMuted)
    }
  }

  @Builder
  ProjectCoverMosaic() {
    Column({ space: AppMetrics.space8 }) {
      Row({ space: AppMetrics.space8 }) {
        this.CoverTile(0)
        this.CoverTile(1)
      }

      Row({ space: AppMetrics.space8 }) {
        this.CoverTile(2)
        this.CoverTile(3)
      }
    }
    .width(AppMetrics.controlHeight * 2 + AppMetrics.space8)
    .height(AppMetrics.controlHeight * 2 + AppMetrics.space8)
    .borderRadius(AppMetrics.cardRadius)
    .clip(true)
    .backgroundColor(AppColors.surfaceMuted)
  }

  build() {
    Row({ space: AppMetrics.space16 }) {
      if (this.summary.recordCount > 0) {
        this.ProjectCoverMosaic()
      } else {
        Column() {
          Text('暂无记录')
            .fontSize(AppTypography.caption)
            .fontColor(AppColors.mutedText)
        }
        .justifyContent(FlexAlign.Center)
        .width(AppMetrics.controlHeight * 2)
        .height(AppMetrics.controlHeight * 2)
        .borderRadius(AppMetrics.cardRadius)
        .backgroundColor(AppColors.surfaceMuted)
      }

      Column({ space: AppMetrics.space8 }) {
        Text(this.summary.project.name)
          .fontSize(AppTypography.body)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.summary.recordCount > 0
          ? `${this.summary.recordCount}张照片 · ${this.summary.recordCount}次思考`
          : '等待第一张照片')
          .fontSize(AppTypography.body)
          .fontColor(AppColors.secondaryText)
          .width('100%')

        Text(this.summary.recordCount > 0 ? `最近更新\n${formatReviewTime(this.summary.latestUpdatedAt)}` : '还没有保存过复盘记录')
          .fontSize(AppTypography.auxiliary)
          .fontColor(AppColors.mutedText)
          .width('100%')
          .lineHeight(AppTypography.auxiliaryLineHeight)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('>')
        .fontSize(AppTypography.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.mutedText)
    }
    .alignItems(VerticalAlign.Center)
    .padding(AppMetrics.space16)
    .width('100%')
    .constraintSize({ minHeight: 124 })
    .borderRadius(AppMetrics.cardRadius)
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
    Stack({ alignContent: Alignment.TopEnd }) {
      Row({ space: AppMetrics.space16 }) {
        ReviewPhotoBlock({
          imageUri: this.item.document.imageUri,
          imageWidth: this.item.document.imageWidth,
          imageHeight: this.item.document.imageHeight,
          imageSizeFallbackUsed: this.item.document.imageSizeFallbackUsed,
          aspectRatioValue: 1,
          compact: true,
          fitMode: ImageFit.Cover,
          cornerRadius: 8
        })
          .width(64)

        Column({ space: AppMetrics.space8 }) {
          Text(this.item.document.content.title.length > 0 ? this.item.document.content.title : '未命名复盘')
            .fontSize(AppTypography.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .padding({ right: AppMetrics.space24 * 3 })

          Text(getReviewProjectExcerpt(this.item.document))
            .fontSize(AppTypography.auxiliary)
            .fontColor(AppColors.secondaryText)
            .lineHeight(AppTypography.auxiliaryLineHeight)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(formatReviewTime(this.item.document.updatedAt))
            .fontSize(AppTypography.caption)
            .fontColor(AppColors.mutedText)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .alignItems(VerticalAlign.Center)
      .padding(AppMetrics.space8)
      .width('100%')
      .constraintSize({ minHeight: 84 })

      ReviewJudgementBadge({ value: this.item.document.content.judgement })
        .margin({ top: AppMetrics.space8, right: AppMetrics.space8 })
    }
    .width('100%')
    .constraintSize({ minHeight: 84 })
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
    Stack({ alignContent: Alignment.TopEnd }) {
      Row({ space: AppMetrics.space16 }) {
        ReviewPhotoBlock({
          imageUri: this.item.document.imageUri,
          imageWidth: this.item.document.imageWidth,
          imageHeight: this.item.document.imageHeight,
          imageSizeFallbackUsed: this.item.document.imageSizeFallbackUsed,
          aspectRatioValue: 1,
          compact: true,
          fitMode: ImageFit.Cover,
          cornerRadius: 8
        })
          .width(68)

        Column({ space: AppMetrics.space8 }) {
          Text(this.item.document.content.title.length > 0 ? this.item.document.content.title : '未命名复盘')
            .fontSize(AppTypography.body)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.text)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
            .padding({ right: AppMetrics.space24 * 3 })

          Text(getReviewProjectExcerpt(this.item.document))
            .fontSize(AppTypography.auxiliary)
            .fontColor(AppColors.secondaryText)
            .lineHeight(AppTypography.auxiliaryLineHeight)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(formatReviewTime(this.item.document.updatedAt))
            .fontSize(AppTypography.caption)
            .fontColor(AppColors.mutedText)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .alignItems(VerticalAlign.Center)
      .padding(AppMetrics.space8)
      .width('100%')
      .constraintSize({ minHeight: 84 })

      ReviewJudgementBadge({ value: this.item.document.content.judgement })
        .margin({ top: AppMetrics.space8, right: AppMetrics.space8 })
    }
    .width('100%')
    .constraintSize({ minHeight: 84 })
    .borderRadius(AppMetrics.cardRadius)
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
        .margin({ top: AppMetrics.space8 })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(AppMetrics.space16)
    .width('100%')
    .borderRadius(AppMetrics.panelRadius)
    .backgroundColor(AppColors.surfaceMuted)
    .border({ width: 1, color: AppColors.border })
  }
}
