import {
  createDefaultReviewCardDocument,
  normalizeReviewJudgement,
  ReviewCardHistoryItem,
  ReviewJudgementStatus
} from '../model/ReviewCardModel';
import { ReviewProjectSummary, createDefaultProjectSummary } from '../model/ProjectModel';
import { getReviewProjectExcerpt } from '../services/ReviewProjectService';
import { formatReviewTime, getImageRatioLabel, getImageSizeText, hasDisplayableImageUri } from '../utils/ImageLayoutUtils';
import {
  ElevationTokens,
  LayoutTokens,
  LineHeightTokens,
  MotionTokens,
  RadiusTokens,
  SpacingTokens,
  TypographyTokens
} from '../theme/DesignTokens';
import { ReviewPhotoBlock } from './ReviewPhotoBlock';

export class AppColors {
  static readonly pageBackground: string = '#F7F5F0';
  static readonly tabBarBackground: string = '#F8F6F1';
  static readonly surface: string = '#FFFEFC';
  static readonly surfaceElevated: string = '#FFFFFF';
  static readonly surfaceMuted: string = '#F3EFE7';
  static readonly surfaceTint: string = '#F8F5EE';
  static readonly border: string = '#E3DBCF';
  static readonly borderStrong: string = '#C8C0B4';
  static readonly borderFocused: string = '#365F75';
  static readonly text: string = '#15191F';
  static readonly secondaryText: string = '#5E6570';
  static readonly mutedText: string = '#8B919A';
  static readonly placeholderText: string = '#727A85';
  static readonly primary: string = '#365F75';
  static readonly primaryPressed: string = '#28495B';
  static readonly primarySoft: string = '#E5EEF3';
  static readonly primaryDisabled: string = '#AFC5D0';
  static readonly onPrimary: string = '#FFFFFF';
  static readonly onPrimarySubtle: string = '#D9FFFFFF';
  static readonly transparent: string = '#00000000';
  static readonly overlayLight: string = '#66FFFFFF';
  static readonly heroGradientMiddle: string = '#0F121B12';
  static readonly heroGradientBlue: string = '#223F542F';
  static readonly heroGradientDeep: string = '#0F121BA0';
  static readonly heroGradientEnd: string = '#0F121B80';
  static readonly scrim: string = '#66000000';
  static readonly modalScrim: string = '#73000000';
  static readonly floatingShadow: string = '#1A000000';
  static readonly shadowSubtle: string = '#0A000000';
  static readonly shadowMedium: string = '#18000000';
  static readonly shadowStrong: string = '#26000000';
  static readonly danger: string = '#B73A31';
  static readonly dangerPressed: string = '#8F2B25';
  static readonly dangerSoft: string = '#F6E8E5';
  static readonly tagBlue: string = '#ECF3F7';
  static readonly tagBlueText: string = '#426A7E';
  static readonly tagGreen: string = '#E7F1EA';
  static readonly tagGreenText: string = '#2E7156';
  static readonly tagAmber: string = '#F3EADA';
  static readonly tagAmberText: string = '#8A6426';
}

export class AppMetrics {
  static readonly space4: number = SpacingTokens.xs;
  static readonly space8: number = SpacingTokens.sm;
  static readonly space10: number = 10;
  static readonly space12: number = SpacingTokens.md;
  static readonly space16: number = SpacingTokens.lg;
  static readonly space20: number = 20;
  static readonly space24: number = SpacingTokens.xl;
  static readonly space32: number = SpacingTokens.xxl;
  static readonly pagePadding: number = 16;
  static readonly pageTopPadding: number = 16;
  static readonly pageBottomPadding: number = 20;
  static readonly sectionGap: number = 20;
  static readonly cardGap: number = 12;
  static readonly cardPadding: number = 16;
  static readonly listCardPadding: number = 12;
  static readonly cardRadius: number = RadiusTokens.lg;
  static readonly buttonRadius: number = RadiusTokens.md;
  static readonly inputRadius: number = RadiusTokens.md;
  static readonly capsuleRadius: number = RadiusTokens.full;
  static readonly panelRadius: number = RadiusTokens.lg;
  static readonly pressInset: number = 8;
  static readonly controlHeight: number = LayoutTokens.PrimaryButtonHeight;
  static readonly searchHeight: number = LayoutTokens.SearchHeight;
  static readonly compactControlHeight: number = LayoutTokens.SecondaryButtonHeight;
  static readonly chipHeight: number = LayoutTokens.ChipHeight;
  static readonly filterChipHeight: number = LayoutTokens.ChipHeight;
  static readonly toolbarButtonHeight: number = 44;
  static readonly toolbarButtonWidth: number = 80;
  static readonly tabBarHeight: number = LayoutTokens.TabBarHeight;
  static readonly tabBarItemHeight: number = LayoutTokens.TabBarItemHeight;
  static readonly tabIconSize: number = TypographyTokens.TabIcon;
  static readonly listThumbnailSize: number = LayoutTokens.ListThumbnailSize;
  static readonly listCardMinHeight: number = LayoutTokens.ListCardMinHeight;
  static readonly listCardMaxHeight: number = LayoutTokens.ListCardMaxHeight;
}

export enum SettingsEntryTone {
  DEFAULT = 'default',
  SUCCESS = 'success',
  WARNING = 'warning',
  DANGER = 'danger',
  MUTED = 'muted'
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
  static readonly bodyStrong: number = TypographyTokens.ButtonText;
  static readonly inputLabel: number = TypographyTokens.InputLabel;
  static readonly inputLabelLineHeight: number = LineHeightTokens.InputLabel;
  static readonly inputText: number = TypographyTokens.InputText;
  static readonly inputTextLineHeight: number = LineHeightTokens.InputText;
  static readonly inputPlaceholder: number = TypographyTokens.InputPlaceholder;
  static readonly tabLabel: number = TypographyTokens.TabLabel;
  static readonly tabLabelLineHeight: number = LineHeightTokens.TabLabel;
  static readonly profileName: number = TypographyTokens.CardTitle;
  static readonly profileNameLineHeight: number = LineHeightTokens.CardTitle;
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
  static readonly auxiliary: number = TypographyTokens.CardMeta;
  static readonly auxiliaryLineHeight: number = LineHeightTokens.CardMeta;
}

@Component
export struct AppPageHeader {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop subtitleTop: number = 6;

  build() {
    Column() {
      Text(this.title)
        .fontSize(AppTypography.pageTitle)
        .fontWeight(700)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.pageTitleLineHeight)
        .maxLines(2)
        .wordBreak(WordBreak.BREAK_WORD)
        .width('100%')
      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(AppTypography.pageSubtitle)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.pageSubtitleLineHeight)
          .maxLines(2)
          .wordBreak(WordBreak.BREAK_WORD)
          .margin({ top: this.subtitleTop })
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}

function resolveSettingsToneTextColor(tone: SettingsEntryTone): string {
  if (tone === SettingsEntryTone.SUCCESS) {
    return AppColors.tagGreenText;
  }
  if (tone === SettingsEntryTone.WARNING) {
    return AppColors.tagAmberText;
  }
  if (tone === SettingsEntryTone.DANGER) {
    return AppColors.danger;
  }
  if (tone === SettingsEntryTone.MUTED) {
    return AppColors.mutedText;
  }
  return AppColors.primary;
}

function resolveSettingsToneBackground(tone: SettingsEntryTone): string {
  if (tone === SettingsEntryTone.SUCCESS) {
    return AppColors.tagGreen;
  }
  if (tone === SettingsEntryTone.WARNING) {
    return AppColors.tagAmber;
  }
  if (tone === SettingsEntryTone.DANGER) {
    return AppColors.dangerSoft;
  }
  if (tone === SettingsEntryTone.MUTED) {
    return AppColors.surfaceMuted;
  }
  return AppColors.primarySoft;
}

@Component
export struct SettingsPageHeader {
  @Prop title: string = '';
  @Prop subtitle: string = '';

  build() {
    Column({ space: 4 }) {
      Text(this.title)
        .fontSize(AppTypography.sectionTitle)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .lineHeight(AppTypography.sectionTitleLineHeight)
        .maxLines(2)
        .wordBreak(WordBreak.BREAK_WORD)
        .width('100%')

      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(AppTypography.body)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.bodyLineHeight)
          .maxLines(2)
          .wordBreak(WordBreak.BREAK_WORD)
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}

@Component
export struct SettingsSectionHeader {
  @Prop title: string = '';
  @Prop description: string = '';

  build() {
    Column({ space: 4 }) {
      Text(this.title)
        .fontSize(AppTypography.meta)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.secondaryText)
        .lineHeight(AppTypography.metaLineHeight)
        .width('100%')

      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.mutedText)
          .lineHeight(AppTypography.captionLineHeight)
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}

@Component
export struct SettingsLinkRow {
  @Prop title: string = '';
  @Prop value: string = '';
  @Prop status: string = '';
  @Prop tone: SettingsEntryTone = SettingsEntryTone.DEFAULT;
  @Prop showChevron: boolean = true;
  @Prop dense: boolean = false;
  @State isPressed: boolean = false;
  onTap: () => void = () => {};

  build() {
    Row({ space: AppMetrics.cardGap }) {
      Column({ space: 4 }) {
        Text(this.title)
          .fontSize(AppTypography.body)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.text)
          .lineHeight(AppTypography.bodyLineHeight)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.value.length > 0) {
          Text(this.value)
            .fontSize(AppTypography.caption)
            .fontColor(AppColors.secondaryText)
            .lineHeight(AppTypography.captionLineHeight)
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.status.length > 0) {
        Text(this.status)
          .fontSize(AppTypography.meta)
          .fontWeight(FontWeight.Medium)
          .fontColor(resolveSettingsToneTextColor(this.tone))
          .lineHeight(AppTypography.metaLineHeight)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(10)
          .backgroundColor(resolveSettingsToneBackground(this.tone))
          .maxLines(1)
      }

      if (this.showChevron) {
        Text('›')
          .fontSize(18)
          .fontColor(AppColors.mutedText)
          .opacity(0.5)
      }
    }
    .alignItems(VerticalAlign.Center)
    .padding({
      left: AppMetrics.cardPadding,
      right: AppMetrics.cardPadding,
      top: this.dense ? AppMetrics.space10 : 14,
      bottom: this.dense ? AppMetrics.space10 : 14
    })
    .width('100%')
    .constraintSize({ minHeight: this.dense ? 60 : 68 })
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(this.isPressed ? AppColors.surfaceMuted : AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(this.isPressed ? ElevationTokens.medium : ElevationTokens.subtle)
    .scale({ x: this.isPressed ? MotionTokens.scaleSubtle : 1, y: this.isPressed ? MotionTokens.scaleSubtle : 1 })
    .animation({ duration: MotionTokens.durationInstant, curve: MotionTokens.curveDecelerate })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
        return;
      }
      if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
    .onClick(() => {
      this.onTap();
    })
  }
}

@Component
export struct PrimaryButton {
  @Prop label: string = '';
  @Prop isDisabled: boolean = false;
  @State isPressed: boolean = false;
  onTap: () => void = () => {};

  build() {
      Button(this.label)
        .height(AppMetrics.controlHeight)
        .width('100%')
        .borderRadius(AppMetrics.buttonRadius)
        .fontSize(AppTypography.buttonText)
        .fontWeight(700)
        .fontColor(AppColors.onPrimary)
        .backgroundColor(this.isDisabled ? AppColors.primaryDisabled : AppColors.primary)
        .border({ width: 1, color: this.isDisabled ? AppColors.primaryDisabled : AppColors.primaryPressed })
        .shadow(this.isDisabled ? ElevationTokens.none : (this.isPressed ? ElevationTokens.subtle : ElevationTokens.low))
        .scale({ x: this.isPressed ? MotionTokens.scalePressed : 1, y: this.isPressed ? MotionTokens.scalePressed : 1 })
        .animation({ duration: MotionTokens.durationInstant, curve: MotionTokens.curveDecelerate })
        .opacity(this.isDisabled ? 0.72 : 1)
        .enabled(!this.isDisabled)
        .stateEffect(!this.isDisabled)
      .onTouch((event: TouchEvent) => {
        if (this.isDisabled) {
          this.isPressed = false;
          return;
        }
        if (event.type === TouchType.Down) {
          this.isPressed = true;
          return;
        }
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.isPressed = false;
        }
      })
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
  @Prop isDisabled: boolean = false;
  @State isPressed: boolean = false;
  onTap: () => void = () => {};

  build() {
      Button(this.label)
        .height(AppMetrics.compactControlHeight)
        .width('100%')
        .borderRadius(AppMetrics.buttonRadius)
        .fontSize(AppTypography.smallButtonText)
        .fontWeight(600)
        .fontColor(this.isDisabled ? AppColors.secondaryText : AppColors.text)
        .backgroundColor(this.isPressed ? AppColors.surfaceMuted : AppColors.surfaceElevated)
        .border({ width: 1, color: AppColors.border })
        .shadow(this.isDisabled ? ElevationTokens.none : ElevationTokens.subtle)
        .scale({ x: this.isPressed ? MotionTokens.scaleSoftPressed : 1, y: this.isPressed ? MotionTokens.scaleSoftPressed : 1 })
        .animation({ duration: MotionTokens.durationInstant, curve: MotionTokens.curveDecelerate })
        .opacity(this.isDisabled ? 0.72 : 1)
        .enabled(!this.isDisabled)
        .stateEffect(!this.isDisabled)
      .onTouch((event: TouchEvent) => {
        if (this.isDisabled) {
          this.isPressed = false;
          return;
        }
        if (event.type === TouchType.Down) {
          this.isPressed = true;
          return;
        }
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.isPressed = false;
        }
      })
      .onClick(() => {
        if (this.isDisabled) {
          return;
        }
        this.onTap();
      })
  }
}

@Component
export struct DangerButton {
  @Prop label: string = '';
  @Prop isDisabled: boolean = false;
  @State isPressed: boolean = false;
  onTap: () => void = () => {};

  build() {
      Button(this.label)
        .height(AppMetrics.compactControlHeight)
        .borderRadius(AppMetrics.buttonRadius)
        .fontSize(AppTypography.smallButtonText)
        .fontWeight(600)
        .fontColor(this.isDisabled ? AppColors.secondaryText : AppColors.danger)
        .backgroundColor(this.isPressed ? AppColors.dangerSoft : AppColors.surfaceTint)
        .border({ width: 1, color: this.isDisabled ? AppColors.border : AppColors.danger })
        .shadow(this.isDisabled ? ElevationTokens.none : (this.isPressed ? ElevationTokens.subtle : ElevationTokens.danger))
        .scale({ x: this.isPressed ? MotionTokens.scaleSoftPressed : 1, y: this.isPressed ? MotionTokens.scaleSoftPressed : 1 })
        .animation({ duration: MotionTokens.durationInstant, curve: MotionTokens.curveDecelerate })
        .opacity(this.isDisabled ? 0.72 : 1)
        .enabled(!this.isDisabled)
        .stateEffect(!this.isDisabled)
      .onTouch((event: TouchEvent) => {
        if (this.isDisabled) {
          this.isPressed = false;
          return;
        }
        if (event.type === TouchType.Down) {
          this.isPressed = true;
          return;
        }
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.isPressed = false;
        }
      })
      .onClick(() => {
        if (this.isDisabled) {
          return;
        }
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
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.text)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .wordBreak(WordBreak.BREAK_WORD)
        .width('100%')
      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(AppTypography.auxiliary)
          .fontColor(AppColors.secondaryText)
          .lineHeight(AppTypography.auxiliaryLineHeight)
          .maxLines(3)
          .wordBreak(WordBreak.BREAK_WORD)
          .textAlign(TextAlign.Center)
          .margin({ top: AppMetrics.space10 })
          .width('100%')
      }
    }
    .alignItems(HorizontalAlign.Center)
    .padding(AppMetrics.space24)
    .width('100%')
    .borderRadius(AppMetrics.cardRadius)
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(ElevationTokens.subtle)
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
      .fontWeight(FontWeight.Bold)
      .fontColor(this.color)
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .borderRadius(AppMetrics.capsuleRadius)
      .backgroundColor(this.tagBackground)
      .shadow(ElevationTokens.subtle)
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

function getJudgementBadgeBackground(value: string): string {
  const judgement: ReviewJudgementStatus = normalizeReviewJudgement(value);
  if (judgement === ReviewJudgementStatus.VALID) {
    return AppColors.tagGreen;
  }
  if (judgement === ReviewJudgementStatus.INVALID) {
    return AppColors.tagAmber;
  }
  return AppColors.primarySoft;
}

@Component
export struct ReviewJudgementBadge {
  @Prop value: string = ReviewJudgementStatus.UNSURE;

  build() {
    Text(getJudgementBadgeText(this.value))
      .fontSize(AppTypography.meta)
      .fontWeight(FontWeight.Medium)
      .fontColor(getJudgementBadgeColor(this.value))
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .borderRadius(10)
      .backgroundColor(getJudgementBadgeBackground(this.value))
      .textAlign(TextAlign.Center)
      .maxLines(1)
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
            Text('照片信息不可用')
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
  @State isPressed: boolean = false;
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
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(this.isPressed ? ElevationTokens.medium : ElevationTokens.subtle)
    .scale({ x: this.isPressed ? MotionTokens.scaleSubtle : 1, y: this.isPressed ? MotionTokens.scaleSubtle : 1 })
    .animation({ duration: MotionTokens.durationInstant, curve: MotionTokens.curveDecelerate })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
        return;
      }
      if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
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
  @State isPressed: boolean = false;
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

      Column({ space: 6 }) {
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
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(this.isPressed ? ElevationTokens.medium : ElevationTokens.subtle)
    .scale({ x: this.isPressed ? MotionTokens.scaleSubtle : 1, y: this.isPressed ? MotionTokens.scaleSubtle : 1 })
    .animation({ duration: MotionTokens.durationInstant, curve: MotionTokens.curveDecelerate })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
        return;
      }
      if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
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
  @State isPressed: boolean = false;
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

      Column({ space: 6 }) {
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
    .backgroundColor(AppColors.surfaceElevated)
    .border({ width: 1, color: AppColors.border })
    .shadow(this.isPressed ? ElevationTokens.medium : ElevationTokens.subtle)
    .scale({ x: this.isPressed ? MotionTokens.scaleSubtle : 1, y: this.isPressed ? MotionTokens.scaleSubtle : 1 })
    .animation({ duration: MotionTokens.durationInstant, curve: MotionTokens.curveDecelerate })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.isPressed = true;
        return;
      }
      if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
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
    .shadow(ElevationTokens.subtle)
  }
}
