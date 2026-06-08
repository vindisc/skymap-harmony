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

function normalizeExportText(value: string): string {
  return value.replace(/\s+/g, ' ').trim();
}

function countExportLines(value: string, textWidth: number, fontSize: number): number {
  const normalizedValue: string = normalizeExportText(value);
  if (normalizedValue.length === 0) {
    return 0;
  }

  const charsPerLine: number = Math.max(10, Math.floor(textWidth / (fontSize * EXPORT_CARD_TEXT_WIDTH_RATIO)));
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
    Math.ceil(EXPORT_CARD_CANVAS_PADDING * 2 + photoHeight + textHeight)
  );
}

@Component
export struct LongFormExportReviewCard {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop exportComponentId: string = '';
  @Prop canvasWidth: number = 1520;
  @Prop canvasHeight: number = 0;

  private getCanvasHeight(): number {
    if (this.canvasHeight > 0) {
      return this.canvasHeight;
    }

    return resolveLongFormExportCardHeight(this.document, this.canvasWidth);
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
          judgement: normalizeReviewJudgement(this.document.content.judgement),
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
    .alignItems(HorizontalAlign.Start)
    .padding(48)
    .width(this.canvasWidth)
    .height(this.getCanvasHeight())
    .id(this.exportComponentId)
    .borderRadius(0)
    .backgroundColor(ReviewCardStyleTokens.canvasColor)
  }
}
