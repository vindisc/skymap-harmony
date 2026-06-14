import {
  createDefaultReviewCardDocument,
  normalizeReviewJudgement,
  ReviewCardHistoryItem,
  ReviewJudgementStatus
} from '../model/ReviewCardModel';
import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import { getReviewProjectExcerpt } from '../services/ReviewProjectService';
import { formatReviewTime, getImageRatioLabel, getImageSizeText, hasDisplayableImageUri } from '../utils/ImageLayoutUtils';
import { LayoutTokens, LineHeightTokens, TypographyTokens } from '../theme/DesignTokens';
import { ReviewPhotoBlock } from './ReviewPhotoBlock';

export class AppColors {
  static readonly pageBackground: string = '#F7F6F3';
  static readonly surface: string = '#FFFEFC';
  static readonly surfaceMuted: string = '#F1EFE9';
  static readonly border: string = '#E5E0D7';
  static readonly borderStrong: string = '#CFC7BA';
  static readonly text: string = '#171A1F';
  static readonly secondaryText: string = '#5E6470';
  static readonly mutedText: string = '#8A8F98';
  static readonly placeholderText: string = '#6F7682';
  static readonly primary: string = '#1B1E23';
  static readonly primaryPressed: string = '#333840';
  static readonly primarySoft: string = '#E6E9E5';
  static readonly onPrimary: string = '#FFFFFF';
  static readonly danger: string = '#B73A31';
  static readonly tagBlue: string = '#EEF4F0';
  static readonly tagBlueText: string = '#496A52';
  static readonly tagGreen: string = '#EAF5ED';
  static readonly tagGreenText: string = '#2E7D5B';
  static readonly tagAmber: string = '#F4EDE1';
  static readonly tagAmberText: string = '#8A6B2F';
}

export class AppMetrics {
  static readonly space8: number = 8;
  static readonly space16: number = 16;
  static readonly space24: number = 24;
  static readonly space32: number = 32;
  static readonly pagePadding: number = 20;
  static readonly pageTopPadding: number = 28;
  static readonly pageBottomPadding: number = 20;
  static readonly sectionGap: number = 18;
  static readonly cardGap: number = 12;
  static readonly cardPadding: number = 16;
  static readonly listCardPadding: number = 12;
  static readonly cardRadius: number = 8;
  static readonly buttonRadius: number = 8;
  static readonly capsuleRadius: number = 16;
  static readonly panelRadius: number = 8;
  static readonly pressInset: number = 8;
  static readonly controlHeight: number = LayoutTokens.PrimaryButtonHeight;
  static readonly searchHeight: number = LayoutTokens.SearchHeight;
  static readonly compactControlHeight: number = LayoutTokens.SecondaryButtonHeight;
  static readonly chipHeight: number = LayoutTokens.ChipHeight;
  static readonly tabBarHeight: number = LayoutTokens.TabBarHeight;
  static readonly tabBarItemHeight: number = LayoutTokens.TabBarItemHeight;
  static readonly tabIconSize: number = TypographyTokens.TabIcon;
  static readonly listThumbnailSize: number = LayoutTokens.ListThumbnailSize;
  static readonly listCardMinHeight: number = LayoutTokens.ListCardMinHeight;
  static readonly listCardMaxHeight: number = LayoutTokens.ListCardMaxHeight;
}

export class AppTypography {
  static readonly pageTitle: number = TypographyTokens.PageTitle;
  static readonly pageTitleLineHeight: number = LineHeightTokens.PageTitle;
  static readonly pageSubtitle: number = TypographyTokens.PageSubtitle;
  static readonly pageSubtitleLineHeight: number = LineHeightTokens.PageSubtitle;
  static readonly sectionTitle: number = TypographyTokens.SectionTitle;
  static readonly sectionTitleLineHeight: number = LineHeightTokens.SectionTitle;
  static readonly sectionSubtitle: number = TypographyTokens.SectionSubtitle;
  static readonly sectionSubtitleLineHeight: number = LineHeightTokens.SectionSubtitle;
  static readonly cardTitle: number = TypographyTokens.CardTitle;
  static readonly cardTitleLineHeight: number = LineHeightTokens.CardTitle;
  static readonly body: number = TypographyTokens.CardBody;
  static readonly bodyLineHeight: number = LineHeightTokens.CardBody;
  static readonly listTitle: number = TypographyTokens.ListTitle;
  static readonly listTitleLineHeight: number = LineHeightTokens.ListTitle;
  static readonly listSubtitle: number = TypographyTokens.ListBody;
  static readonly listSubtitleLineHeight: number = LineHeightTokens.ListBody;
  static readonly caption: number = TypographyTokens.SectionSubtitle;
  static readonly captionLineHeight: number = LineHeightTokens.SectionSubtitle;
  static readonly meta: number = TypographyTokens.CardMeta;
  static readonly metaLineHeight: number = LineHeightTokens.CardMeta;
  static readonly buttonText: number = TypographyTokens.ButtonText;
  static readonly buttonTextLineHeight: number = LineHeightTokens.ButtonText;
  static readonly smallButtonText: number = TypographyTokens.SmallButtonText;
  static readonly inputLabel: number = TypographyTokens.InputLabel;
  static readonly inputLabelLineHeight: number = LineHeightTokens.InputLabel;
  static readonly inputText: number = TypographyTokens.InputText;
  static readonly inputTextLineHeight: number = LineHeightTokens.InputText;
  static readonly inputPlaceholder: number = TypographyTokens.InputPlaceholder;
  static readonly tabLabel: number = TypographyTokens.TabLabel;
  static readonly tabLabelLineHeight: number = LineHeightTokens.TabLabel;
  static readonly profileName: number = 24;
  static readonly profileNameLineHeight: number = 30;
  static readonly statNumber: number = TypographyTokens.StatNumber;
  static readonly statNumberLineHeight: number = LineHeightTokens.StatNumber;
  static readonly statLabel: number = TypographyTokens.StatLabel;
  static readonly statLabelLineHeight: number = LineHeightTokens.StatLabel;
  static readonly level1: number = TypographyTokens.PageTitle;
  static readonly level1LineHeight: number = LineHeightTokens.PageTitle;
  static readonly level2: number = TypographyTokens.SectionTitle;
  static readonly level2LineHeight: number = LineHeightTokens.SectionTitle;
  static readonly level3: number = TypographyTokens.CardTitle;
  static readonly level3LineHeight: number = LineHeightTokens.CardTitle;
  static readonly auxiliary: number = TypographyTokens.ListBody;
  static readonly auxiliaryLineHeight: number = LineHeightTokens.ListBody;
}

@Component
export struct AppPageHeader {
  @Prop title: string = '';
  @Prop subtitle: string = '';

  build() {
    Column() {
      Text(this.title)
        .fontSize(AppTypography.pageTitle)
        .fontWeight(700)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.pageTitleLineHeight)
        .width('100%')
      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(AppTypography.pageSubtitle)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.pageSubtitleLineHeight)
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
      .fontSize(AppTypography.buttonText)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.onPrimary)
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
      .fontSize(AppTypography.smallButtonText)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.text)
      .backgroundColor(AppColors.surfaceMuted)

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
        .fontSize(AppTypography.cardTitle)
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
      .fontSize(AppTypography.meta)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.color)
      .padding({ left: AppMetrics.space8, right: AppMetrics.space8, top: 5, bottom: 5 })
      .borderRadius(AppMetrics.cardRadius)
      .backgroundColor(this.tagBackground)
  }
}

function getJudgementBadgeText(value: string): string {
  const judgement: ReviewJudgementStatus = normalizeReviewJudgement(value);
  if (judgement === ReviewJudgementStatus.VALID) {
    return '成立';
  }
  if (judgement === ReviewJudgementStatus.INVALID) {
    return '不成立';
  }
  return '待判断';
}

function getJudgementBadgeColor(value: string): string {
  const judgement: ReviewJudgementStatus = normalizeReviewJudgement(value);
  if (judgement === ReviewJudgementStatus.VALID) {
    return AppColors.tagGreenText;
  }
  if (judgement === ReviewJudgementStatus.INVALID) {
    return AppColors.tagAmberText;
  }
  return AppColors.secondaryText;
}

function getJudgementBadgeBackground(_value: string): string {
  return AppColors.surfaceMuted;
}

@Component
export struct ReviewJudgementBadge {
  @Prop value: string = ReviewJudgementStatus.UNSURE;

  build() {
    Text(getJudgementBadgeText(this.value))
      .fontSize(AppTypography.meta)
      .fontWeight(FontWeight.Regular)
      .fontColor(getJudgementBadgeColor(this.value))
      .padding({ left: AppMetrics.space8, right: AppMetrics.space8, top: 5, bottom: 5 })
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
            .fontSize(AppTypography.cardTitle)
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
    .backgroundColor(AppColors.surfaceMuted)
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
      .backgroundColor(AppColors.surfaceMuted)
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
    Row({ space: AppMetrics.cardGap }) {
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
          .fontSize(AppTypography.cardTitle)
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

      Text('›')
        .fontSize(AppTypography.cardTitle)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.mutedText)
    }
    .alignItems(VerticalAlign.Center)
    .padding(AppMetrics.cardPadding)
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
    Row({ space: AppMetrics.cardGap }) {
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
        .width(AppMetrics.listThumbnailSize)

      Column({ space: 5 }) {
        Text(this.item.document.content.title.length > 0 ? this.item.document.content.title : '未命名复盘')
          .fontSize(AppTypography.listTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.listTitleLineHeight)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(getReviewProjectExcerpt(this.item.document))
          .fontSize(AppTypography.listSubtitle)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.listSubtitleLineHeight)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: AppMetrics.space8 }) {
          Text(formatReviewTime(this.item.document.updatedAt))
            .fontSize(AppTypography.meta)
            .fontColor(AppColors.mutedText)
            .lineHeight(AppTypography.metaLineHeight)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          ReviewJudgementBadge({ value: this.item.document.content.judgement })
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Center)
    .padding(AppMetrics.listCardPadding)
    .width('100%')
    .constraintSize({ minHeight: AppMetrics.listCardMinHeight, maxHeight: AppMetrics.listCardMaxHeight })
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
    Row({ space: AppMetrics.cardGap }) {
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
        .width(AppMetrics.listThumbnailSize)

      Column({ space: 5 }) {
        Text(this.item.document.content.title.length > 0 ? this.item.document.content.title : '未命名复盘')
          .fontSize(AppTypography.listTitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.listTitleLineHeight)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(getReviewProjectExcerpt(this.item.document))
          .fontSize(AppTypography.listSubtitle)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.listSubtitleLineHeight)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: AppMetrics.space8 }) {
          Text(formatReviewTime(this.item.document.updatedAt))
            .fontSize(AppTypography.meta)
            .fontColor(AppColors.mutedText)
            .lineHeight(AppTypography.metaLineHeight)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          ReviewJudgementBadge({ value: this.item.document.content.judgement })
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Center)
    .padding(AppMetrics.listCardPadding)
    .width('100%')
    .constraintSize({ minHeight: AppMetrics.listCardMinHeight, maxHeight: AppMetrics.listCardMaxHeight })
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
