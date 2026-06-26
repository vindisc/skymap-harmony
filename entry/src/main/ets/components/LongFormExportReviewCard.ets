import {
  createDefaultReviewCardDocument,
  normalizeReviewJudgement,
  ReviewCardDocument
} from '../model/ReviewCardModel';
import { resolveReviewCardLayoutResolution } from '../model/ReviewCardLayout';
import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewPhotoArea } from './ReviewPhotoArea';
import { ReviewCardTitle } from './ReviewCardTitle';
import { ReviewInfoGroup } from './ReviewInfoGroup';
import { formatReviewTime } from '../utils/ImageLayoutUtils';

export class CompactReviewTextStyle {
  static readonly titleSize: number = 32;
  static readonly titleLineHeight: number = 44;
  static readonly labelSize: number = 15;
  static readonly labelLineHeight: number = 20;
  static readonly bodySize: number = 22;
  static readonly bodyLineHeight: number = 31;
  static readonly valueTopGap: number = 4;
  static readonly dividerBottomGap: number = 7;
  static readonly itemBottomGap: number = 9;
}

const EXPORT_CARD_CANVAS_PADDING: number = 48;
const EXPORT_CARD_TEXT_TOP_PADDING: number = 18;
const EXPORT_CARD_META_TOP_MARGIN: number = 6;
const EXPORT_CARD_META_LINE_HEIGHT: number = 24;
const EXPORT_CARD_META_SIZE: number = 18;
const EXPORT_CARD_INFO_TOP_MARGIN: number = 14;
const EXPORT_CARD_DIVIDER_HEIGHT: number = 1;
const EXPORT_CARD_MIN_HEIGHT: number = 640;
const EXPORT_CARD_TEXT_WIDTH_RATIO: number = 0.92;
const EXPORT_CARD_BOTTOM_SAFETY_PADDING: number = 120;
const EXPORT_CARD_HORIZONTAL_BAR_TOP_MARGIN: number = 20;
const EXPORT_CARD_HORIZONTAL_PANEL_TOP_MARGIN: number = 14;
const EXPORT_CARD_HORIZONTAL_PANEL_PADDING: number = 28;
const EXPORT_CARD_HORIZONTAL_COLUMN_GAP: number = 34;
const EXPORT_CARD_HORIZONTAL_PILL_HEIGHT: number = 40;
const EXPORT_CARD_HORIZONTAL_TITLE_BAR_MIN_HEIGHT: number = 92;
const EXPORT_CARD_HORIZONTAL_PANEL_MIN_HEIGHT: number = 260;
const EXPORT_CARD_HORIZONTAL_BOTTOM_SAFE_GAP: number = 88;
const EXPORT_CARD_HORIZONTAL_HEIGHT_SAFETY_PADDING: number = 36;
const EXPORT_CARD_HORIZONTAL_LINE_WIDTH_RATIO: number = 0.76;

const EXPORT_GUIDANCE_TOKENS: Array<string> = [
  '第一眼先看到哪里',
  '为什么它会先被看到',
  '视线接着从哪里走到哪里',
  '画面里有哪些可见事实',
  '最重要的 A ↔ B 关系是什么',
  '这张照片为什么成立或不成立',
  '当前最大问题是什么',
  '第一眼落点',
  '落点原因',
  '视线路径',
  '画面事实',
  '核心关系',
  '延伸理解',
  '当前卡点'
];

interface ExportInfoItem {
  label: string;
  value: string;
}

function normalizeExportText(value: string): string {
  return value.replace(/\s+/g, ' ').trim();
}

function stripExportDisplayNoise(value: string): string {
  return value
    .replace(/https?:\/\/[^\s，。；、]+/g, ' ')
    .replace(/\d{12,}/g, ' ')
    .replace(/[＿_—-]{6,}/g, ' ');
}

function isExportGuidanceText(value: string): boolean {
  const normalizedValue: string = normalizeExportText(value);
  if (normalizedValue.length === 0) {
    return true;
  }

  let matchedCount: number = 0;
  EXPORT_GUIDANCE_TOKENS.forEach((token: string): void => {
    if (normalizedValue.includes(token)) {
      matchedCount += 1;
    }
  });

  return matchedCount >= 2;
}

function cleanExportDisplayText(value: string): string {
  const withoutNoise: string = normalizeExportText(stripExportDisplayNoise(value));
  if (isExportGuidanceText(withoutNoise)) {
    return '';
  }

  return withoutNoise;
}

function countExportLines(value: string, textWidth: number, fontSize: number): number {
  const normalizedValue: string = normalizeExportText(value);
  if (normalizedValue.length === 0) {
    return 0;
  }

  const charsPerLine: number = Math.max(10, Math.floor(textWidth / (fontSize * EXPORT_CARD_TEXT_WIDTH_RATIO)));
  return Math.max(1, Math.ceil(normalizedValue.length / charsPerLine));
}

function countHorizontalExportLines(value: string, textWidth: number, fontSize: number): number {
  const normalizedValue: string = cleanExportDisplayText(value);
  if (normalizedValue.length === 0) {
    return 0;
  }

  const charsPerLine: number = Math.max(8, Math.floor(textWidth / (fontSize * EXPORT_CARD_HORIZONTAL_LINE_WIDTH_RATIO)));
  return Math.max(1, Math.ceil(normalizedValue.length / charsPerLine));
}

function getExportFieldValues(document: ReviewCardDocument): Array<string> {
  const fieldValues: Array<string> = [
    document.content.visualFocus,
    document.content.focusReason,
    document.content.visualPath,
    document.content.visibleFacts,
    document.content.coreRelation,
    normalizeReviewJudgement(document.content.judgement),
    document.content.extendedUnderstanding,
    document.content.currentBlocker
  ];
  return fieldValues.filter((value: string): boolean => normalizeExportText(value).length > 0);
}

function isHorizontalExportPhoto(document: ReviewCardDocument): boolean {
  return document.imageWidth > document.imageHeight;
}

function createExportInfoItem(label: string, value: string): ExportInfoItem {
  return {
    label: label,
    value: cleanExportDisplayText(value)
  };
}

function getHorizontalProcessItems(document: ReviewCardDocument): Array<ExportInfoItem> {
  const items: Array<ExportInfoItem> = [
    createExportInfoItem('视觉落点', document.content.visualFocus),
    createExportInfoItem('视线路径', document.content.visualPath),
    createExportInfoItem('画面事实', document.content.visibleFacts)
  ];
  return items.filter((item: ExportInfoItem): boolean => item.value.length > 0);
}

function getHorizontalSummaryItems(document: ReviewCardDocument): Array<ExportInfoItem> {
  const items: Array<ExportInfoItem> = [
    createExportInfoItem('最强关系', document.content.coreRelation),
    createExportInfoItem('卡点', document.content.currentBlocker),
    createExportInfoItem('复盘信息', document.content.extendedUnderstanding)
  ];
  return items.filter((item: ExportInfoItem): boolean => item.value.length > 0);
}

function resolveExportInfoListHeight(items: Array<ExportInfoItem>, textWidth: number): number {
  let height: number = 0;
  items.forEach((item: ExportInfoItem): void => {
    const bodyLines: number = countHorizontalExportLines(item.value, textWidth, CompactReviewTextStyle.bodySize);
    height += CompactReviewTextStyle.labelLineHeight
      + CompactReviewTextStyle.valueTopGap
      + Math.max(1, bodyLines) * CompactReviewTextStyle.bodyLineHeight
      + CompactReviewTextStyle.itemBottomGap;
  });
  return height;
}

function getExportJudgementText(value: string): string {
  const judgement = normalizeReviewJudgement(value);
  if (judgement === '成立') {
    return '成立';
  }
  if (judgement === '不成立') {
    return '不成立';
  }
  return '待判断';
}

export function resolveLongFormExportCardHeight(document: ReviewCardDocument, canvasWidth: number): number {
  const contentWidth: number = Math.max(1, canvasWidth - EXPORT_CARD_CANVAS_PADDING * 2);
  const aspectRatio: number = resolveReviewCardLayoutResolution(document).aspectRatio;
  const photoHeight: number = contentWidth / Math.max(0.1, aspectRatio);
  if (isHorizontalExportPhoto(document)) {
    const titleLines: number = countExportLines(document.content.title, contentWidth * 0.72, CompactReviewTextStyle.titleSize);
    const titleBarHeight: number = Math.max(
      EXPORT_CARD_HORIZONTAL_TITLE_BAR_MIN_HEIGHT,
      EXPORT_CARD_TEXT_TOP_PADDING
        + Math.max(1, titleLines) * CompactReviewTextStyle.titleLineHeight
        + EXPORT_CARD_META_TOP_MARGIN
        + EXPORT_CARD_META_LINE_HEIGHT
        + 18
    );
    const columnWidth: number = Math.max(
      1,
      (contentWidth - EXPORT_CARD_HORIZONTAL_PANEL_PADDING * 2 - EXPORT_CARD_HORIZONTAL_COLUMN_GAP) / 2
    );
    const processHeight: number = resolveExportInfoListHeight(getHorizontalProcessItems(document), columnWidth);
    const summaryHeight: number = resolveExportInfoListHeight(getHorizontalSummaryItems(document), columnWidth);
    const panelHeight: number = Math.max(
      EXPORT_CARD_HORIZONTAL_PANEL_MIN_HEIGHT,
      EXPORT_CARD_HORIZONTAL_PANEL_PADDING * 2
        + Math.max(processHeight, summaryHeight)
        + EXPORT_CARD_HORIZONTAL_HEIGHT_SAFETY_PADDING
    );

    return Math.max(
      EXPORT_CARD_MIN_HEIGHT,
      Math.ceil(
        EXPORT_CARD_CANVAS_PADDING * 2
          + photoHeight
          + EXPORT_CARD_HORIZONTAL_BAR_TOP_MARGIN
          + titleBarHeight
          + EXPORT_CARD_HORIZONTAL_PANEL_TOP_MARGIN
          + panelHeight
          + EXPORT_CARD_HORIZONTAL_BOTTOM_SAFE_GAP
      )
    );
  }

  const titleLines: number = countExportLines(document.content.title, contentWidth, CompactReviewTextStyle.titleSize);
  const titleHeight: number = Math.max(1, titleLines) * CompactReviewTextStyle.titleLineHeight;
  const fieldValues: Array<string> = getExportFieldValues(document);
  let infoHeight: number = 0;

  fieldValues.forEach((value: string, index: number): void => {
    const bodyLines: number = countExportLines(value, contentWidth, CompactReviewTextStyle.bodySize);
    infoHeight += CompactReviewTextStyle.labelLineHeight
      + CompactReviewTextStyle.valueTopGap
      + Math.max(1, bodyLines) * CompactReviewTextStyle.bodyLineHeight
      + CompactReviewTextStyle.itemBottomGap;
    if (index > 0) {
      infoHeight += EXPORT_CARD_DIVIDER_HEIGHT + CompactReviewTextStyle.dividerBottomGap;
    }
  });

  const textHeight: number = EXPORT_CARD_TEXT_TOP_PADDING
    + titleHeight
    + EXPORT_CARD_META_TOP_MARGIN
    + EXPORT_CARD_META_LINE_HEIGHT
    + (fieldValues.length > 0 ? EXPORT_CARD_INFO_TOP_MARGIN + infoHeight : 0);
  return Math.max(
    EXPORT_CARD_MIN_HEIGHT,
    Math.ceil(EXPORT_CARD_CANVAS_PADDING * 2 + photoHeight + textHeight + EXPORT_CARD_BOTTOM_SAFETY_PADDING)
  );
}

@Component
export struct LongFormExportReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop reviewerText: string = '';
  @Prop exportComponentId: string = '';
  @Prop canvasWidth: number = 1520;
  @Prop canvasHeight: number = 0;

  private getCanvasHeight(): number {
    if (this.canvasHeight > 0) {
      return this.canvasHeight;
    }

    return resolveLongFormExportCardHeight(this.document, this.canvasWidth);
  }

  private hasValue(value: string): boolean {
    return cleanExportDisplayText(value).length > 0;
  }

  private getMetaText(): string {
    const timeText: string = formatReviewTime(this.document.updatedAt);
    const reviewerText: string = normalizeExportText(this.reviewerText);
    if (reviewerText.length > 0) {
      return `${timeText} / ${reviewerText}`;
    }
    return timeText;
  }

  @Builder
  JudgementPill() {
    Text(getExportJudgementText(this.document.content.judgement))
      .fontSize(19)
      .fontWeight(FontWeight.Medium)
      .fontColor('#5B625F')
      .lineHeight(24)
      .padding({ left: 20, right: 20 })
      .height(EXPORT_CARD_HORIZONTAL_PILL_HEIGHT)
      .borderRadius(20)
      .backgroundColor('#ECE8DE')
      .border({ width: 1, color: '#DCD3C3' })
      .maxLines(1)
      .textAlign(TextAlign.Center)
  }

  @Builder
  HorizontalTitleBar() {
    Row({ space: 24 }) {
      Column() {
        ReviewCardTitle({
          title: this.document.content.title,
          titleSize: CompactReviewTextStyle.titleSize,
          titleLineHeight: CompactReviewTextStyle.titleLineHeight
        })

        Text(this.getMetaText())
          .fontSize(EXPORT_CARD_META_SIZE)
          .lineHeight(EXPORT_CARD_META_LINE_HEIGHT)
          .fontColor('#8D929A')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: EXPORT_CARD_META_TOP_MARGIN })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      this.JudgementPill()
    }
    .alignItems(VerticalAlign.Center)
    .padding({ left: 30, right: 30, top: 18, bottom: 18 })
    .width('100%')
    .constraintSize({ minHeight: EXPORT_CARD_HORIZONTAL_TITLE_BAR_MIN_HEIGHT })
    .borderRadius(18)
    .backgroundColor('#FBFAF6')
    .border({ width: 1, color: '#E7DFD2' })
    .margin({ top: EXPORT_CARD_HORIZONTAL_BAR_TOP_MARGIN })
  }

  @Builder
  HorizontalInfoItem(label: string, value: string) {
    if (this.hasValue(value)) {
      Column() {
        Text(label)
          .fontSize(CompactReviewTextStyle.labelSize)
          .lineHeight(CompactReviewTextStyle.labelLineHeight)
          .fontWeight(FontWeight.Medium)
          .fontColor('#929085')
          .maxLines(1)
          .width('100%')

        Text(cleanExportDisplayText(value))
          .fontSize(CompactReviewTextStyle.bodySize)
          .lineHeight(CompactReviewTextStyle.bodyLineHeight)
          .fontColor('#343635')
          .fontWeight(FontWeight.Regular)
          .wordBreak(WordBreak.BREAK_WORD)
          .lineBreakStrategy(LineBreakStrategy.HIGH_QUALITY)
          .textOverflow({ overflow: TextOverflow.Clip })
          .margin({ top: CompactReviewTextStyle.valueTopGap })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ bottom: CompactReviewTextStyle.itemBottomGap })
    }
  }

  @Builder
  HorizontalInfoColumn(isProcessColumn: boolean) {
    Column() {
      if (isProcessColumn) {
        this.HorizontalInfoItem('视觉落点', this.document.content.visualFocus)
        this.HorizontalInfoItem('视线路径', this.document.content.visualPath)
        this.HorizontalInfoItem('画面事实', this.document.content.visibleFacts)
      } else {
        this.HorizontalInfoItem('最强关系', this.document.content.coreRelation)
        this.HorizontalInfoItem('卡点', this.document.content.currentBlocker)
        this.HorizontalInfoItem('复盘信息', this.document.content.extendedUnderstanding)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
  }

  @Builder
  HorizontalReviewPanel() {
    Row({ space: EXPORT_CARD_HORIZONTAL_COLUMN_GAP }) {
      this.HorizontalInfoColumn(true)

      Column()
        .width(1)
        .height('100%')
        .backgroundColor('#E4DCCE')

      this.HorizontalInfoColumn(false)
    }
    .alignItems(VerticalAlign.Top)
    .padding(EXPORT_CARD_HORIZONTAL_PANEL_PADDING)
    .width('100%')
    .constraintSize({ minHeight: EXPORT_CARD_HORIZONTAL_PANEL_MIN_HEIGHT })
    .borderRadius(20)
    .backgroundColor('#F5F1E8')
    .border({ width: 1, color: '#E2D8C8' })
    .margin({ top: EXPORT_CARD_HORIZONTAL_PANEL_TOP_MARGIN, bottom: EXPORT_CARD_HORIZONTAL_BOTTOM_SAFE_GAP })
  }

  @Builder
  DefaultTextContent() {
    Column() {
      ReviewCardTitle({
        title: this.document.content.title,
        titleSize: CompactReviewTextStyle.titleSize,
        titleLineHeight: CompactReviewTextStyle.titleLineHeight
      })

      Row() {
        Text(formatReviewTime(this.document.updatedAt))
          .fontSize(EXPORT_CARD_META_SIZE)
          .lineHeight(EXPORT_CARD_META_LINE_HEIGHT)
          .fontColor('#8D929A')
          .maxLines(1)

        Blank()

        Text(getExportJudgementText(this.document.content.judgement))
          .fontSize(EXPORT_CARD_META_SIZE)
          .lineHeight(EXPORT_CARD_META_LINE_HEIGHT)
          .fontColor('#8D929A')
          .textAlign(TextAlign.End)
          .maxLines(1)
      }
      .width('100%')
      .margin({ top: EXPORT_CARD_META_TOP_MARGIN })

      ReviewInfoGroup({
        visualFocus: this.document.content.visualFocus,
        focusReason: this.document.content.focusReason,
        visualPath: this.document.content.visualPath,
        visibleFacts: this.document.content.visibleFacts,
        coreRelation: this.document.content.coreRelation,
        judgement: getExportJudgementText(this.document.content.judgement),
        extendedUnderstanding: this.document.content.extendedUnderstanding,
        currentBlocker: this.document.content.currentBlocker,
        labelSize: CompactReviewTextStyle.labelSize,
        labelLineHeight: CompactReviewTextStyle.labelLineHeight,
        bodySize: CompactReviewTextStyle.bodySize,
        bodyLineHeight: CompactReviewTextStyle.bodyLineHeight,
        labelColor: '#8D929A',
        bodyColor: ReviewCardStyleTokens.bodyColor,
        dividerColor: '#ECE5DA',
        valueTopGap: CompactReviewTextStyle.valueTopGap,
        dividerBottomGap: CompactReviewTextStyle.dividerBottomGap,
        itemBottomGap: CompactReviewTextStyle.itemBottomGap
      })
        .margin({ top: EXPORT_CARD_INFO_TOP_MARGIN })
    }
    .padding({ top: 18 })
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  build() {
    Column() {
      ReviewPhotoArea({
        imageUri: this.document.imageUri,
        imageWidth: this.document.imageWidth,
        imageHeight: this.document.imageHeight,
        imageSizeFallbackUsed: this.document.imageSizeFallbackUsed,
        aspectRatioValue: resolveReviewCardLayoutResolution(this.document).aspectRatio,
        cornerRadius: 22
      })

      if (isHorizontalExportPhoto(this.document)) {
        this.HorizontalTitleBar()
        this.HorizontalReviewPanel()
      } else {
        this.DefaultTextContent()
      }
    }
    .alignItems(HorizontalAlign.Start)
    .padding(48)
    .width(this.canvasWidth)
    .height(this.getCanvasHeight())
    .id(this.exportComponentId)
    .borderRadius(0)
    .backgroundColor(ReviewCardStyleTokens.canvasColor)
  }
}
