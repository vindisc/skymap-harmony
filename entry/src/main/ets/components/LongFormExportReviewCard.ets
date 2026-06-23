import {
  createDefaultReviewCardDocument,
  normalizeReviewJudgement,
  ReviewCardDocument,
  ReviewCardLayoutType
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
  static readonly panelTitleSize: number = 16;
  static readonly panelTitleLineHeight: number = 24;
  static readonly judgementLabelSize: number = 15;
  static readonly judgementLabelLineHeight: number = 20;
  static readonly judgementSize: number = 28;
  static readonly judgementLineHeight: number = 38;
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
const EXPORT_HORIZONTAL_COLUMN_GAP: number = 28;
const EXPORT_HORIZONTAL_LEFT_COLUMN_RATIO: number = 0.6;
const EXPORT_HORIZONTAL_TITLE_BOTTOM_GAP: number = 20;
const EXPORT_HORIZONTAL_PANEL_BOTTOM_GAP: number = 20;
const EXPORT_HORIZONTAL_SECTION_GAP: number = 18;
const EXPORT_HORIZONTAL_JUDGEMENT_TOP_GAP: number = 12;
const EXPORT_HORIZONTAL_JUDGEMENT_PADDING: number = 16;
const EXPORT_HORIZONTAL_JUDGEMENT_RADIUS: number = 18;

interface ExportSectionItem {
  label: string;
  value: string;
}

interface HorizontalColumnWidths {
  leftWidth: number;
  rightWidth: number;
}

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

function hasExportValue(value: string): boolean {
  return normalizeExportText(value).length > 0;
}

function isHorizontalExportLayout(document: ReviewCardDocument): boolean {
  return resolveReviewCardLayoutResolution(document).layoutType === ReviewCardLayoutType.HORIZONTAL;
}

function resolveHorizontalColumnWidths(contentWidth: number): HorizontalColumnWidths {
  const availableWidth = Math.max(1, contentWidth - EXPORT_HORIZONTAL_COLUMN_GAP);
  const leftWidth = Math.max(1, Math.floor(availableWidth * EXPORT_HORIZONTAL_LEFT_COLUMN_RATIO));
  const rightWidth = Math.max(1, availableWidth - leftWidth);
  return { leftWidth, rightWidth };
}

function createHorizontalProcessSections(document: ReviewCardDocument): Array<ExportSectionItem> {
  const sections: Array<ExportSectionItem> = [];
  if (hasExportValue(document.content.visualFocus)) {
    sections.push({ label: '视觉落点', value: document.content.visualFocus });
  }
  if (hasExportValue(document.content.visualPath)) {
    sections.push({ label: '视线路径', value: document.content.visualPath });
  }
  if (hasExportValue(document.content.visibleFacts)) {
    sections.push({ label: '画面事实', value: document.content.visibleFacts });
  }
  return sections;
}

function createHorizontalSummarySections(document: ReviewCardDocument): Array<ExportSectionItem> {
  const sections: Array<ExportSectionItem> = [];
  if (hasExportValue(document.content.coreRelation)) {
    sections.push({ label: '最强关系', value: document.content.coreRelation });
  }
  sections.push({
    label: '卡点',
    value: hasExportValue(document.content.currentBlocker) ? document.content.currentBlocker : '暂无明显卡点'
  });
  return sections;
}

function resolveHorizontalReviewMeta(document: ReviewCardDocument, reviewerName: string): Array<string> {
  const lines: Array<string> = [];
  if (hasExportValue(reviewerName)) {
    lines.push(`复盘人 · ${normalizeExportText(reviewerName)}`);
  }
  lines.push(formatReviewTime(document.updatedAt));
  return lines;
}

function estimateHorizontalSectionHeight(section: ExportSectionItem, width: number): number {
  const bodyLines: number = countExportLines(section.value, width, CompactReviewTextStyle.bodySize);
  return CompactReviewTextStyle.labelLineHeight
    + CompactReviewTextStyle.valueTopGap
    + Math.max(1, bodyLines) * CompactReviewTextStyle.bodyLineHeight
    + CompactReviewTextStyle.itemBottomGap;
}

function resolveHorizontalColumnsHeight(document: ReviewCardDocument, contentWidth: number, reviewerName: string): number {
  const columnWidths: HorizontalColumnWidths = resolveHorizontalColumnWidths(contentWidth);
  const leftWidth: number = columnWidths.leftWidth;
  const rightWidth: number = columnWidths.rightWidth;
  const leftSections = createHorizontalProcessSections(document);
  const rightSections = createHorizontalSummarySections(document);
  const leftPanelTitleHeight = CompactReviewTextStyle.panelTitleLineHeight + EXPORT_HORIZONTAL_PANEL_BOTTOM_GAP;
  const rightPanelTitleHeight = CompactReviewTextStyle.panelTitleLineHeight + EXPORT_HORIZONTAL_PANEL_BOTTOM_GAP;

  let leftHeight = leftPanelTitleHeight;
  leftSections.forEach((section: ExportSectionItem, index: number): void => {
    leftHeight += estimateHorizontalSectionHeight(section, leftWidth);
    if (index < leftSections.length - 1) {
      leftHeight += EXPORT_HORIZONTAL_SECTION_GAP;
    }
  });

  const judgementHeight = CompactReviewTextStyle.judgementLabelLineHeight
    + EXPORT_HORIZONTAL_JUDGEMENT_TOP_GAP
    + CompactReviewTextStyle.judgementLineHeight
    + EXPORT_HORIZONTAL_JUDGEMENT_PADDING * 2;
  let rightHeight = rightPanelTitleHeight + judgementHeight + EXPORT_HORIZONTAL_SECTION_GAP;

  rightSections.forEach((section: ExportSectionItem, index: number): void => {
    rightHeight += estimateHorizontalSectionHeight(section, rightWidth);
    rightHeight += EXPORT_HORIZONTAL_SECTION_GAP;
  });

  const metaLines = resolveHorizontalReviewMeta(document, reviewerName);
  rightHeight += CompactReviewTextStyle.labelLineHeight
    + CompactReviewTextStyle.valueTopGap
    + metaLines.length * CompactReviewTextStyle.labelLineHeight;

  return Math.max(leftHeight, rightHeight);
}

export function resolveLongFormExportCardHeight(
  document: ReviewCardDocument,
  canvasWidth: number,
  reviewerName: string = ''
): number {
  const contentWidth: number = Math.max(1, canvasWidth - EXPORT_CARD_CANVAS_PADDING * 2);
  const aspectRatio: number = resolveReviewCardLayoutResolution(document).aspectRatio;
  const photoHeight: number = contentWidth / Math.max(0.1, aspectRatio);
  const titleLines: number = countExportLines(document.content.title, contentWidth, CompactReviewTextStyle.titleSize);
  const titleHeight: number = Math.max(1, titleLines) * CompactReviewTextStyle.titleLineHeight;

  if (isHorizontalExportLayout(document)) {
    const textHeight: number = EXPORT_CARD_TEXT_TOP_PADDING
      + titleHeight
      + EXPORT_HORIZONTAL_TITLE_BOTTOM_GAP
      + resolveHorizontalColumnsHeight(document, contentWidth, reviewerName);
    return Math.max(
      EXPORT_CARD_MIN_HEIGHT,
      Math.ceil(EXPORT_CARD_CANVAS_PADDING * 2 + photoHeight + textHeight + EXPORT_CARD_BOTTOM_SAFETY_PADDING)
    );
  }

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
  @Prop exportComponentId: string = '';
  @Prop canvasWidth: number = 1520;
  @Prop canvasHeight: number = 0;
  @Prop reviewerName: string = '';

  private getCanvasHeight(): number {
    if (this.canvasHeight > 0) {
      return this.canvasHeight;
    }

    return resolveLongFormExportCardHeight(this.document, this.canvasWidth, this.reviewerName);
  }

  private isHorizontalLayout(): boolean {
    return isHorizontalExportLayout(this.document);
  }

  private hasValue(value: string): boolean {
    return hasExportValue(value);
  }

  private getJudgementLabel(): string {
    return getExportJudgementText(this.document.content.judgement);
  }

  @Builder
  private HorizontalPanelTitle(title: string) {
    Text(title)
      .fontSize(CompactReviewTextStyle.panelTitleSize)
      .fontWeight(FontWeight.Medium)
      .fontColor(ReviewCardStyleTokens.inkColor)
      .lineHeight(CompactReviewTextStyle.panelTitleLineHeight)
      .width('100%')
  }

  @Builder
  private HorizontalSection(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(CompactReviewTextStyle.labelSize)
        .fontWeight(FontWeight.Medium)
        .fontColor(ReviewCardStyleTokens.labelColor)
        .lineHeight(CompactReviewTextStyle.labelLineHeight)
        .width('100%')

      Text(value)
        .fontSize(CompactReviewTextStyle.bodySize)
        .fontColor(ReviewCardStyleTokens.bodyColor)
        .lineHeight(CompactReviewTextStyle.bodyLineHeight)
        .margin({ top: CompactReviewTextStyle.valueTopGap })
        .width('100%')
        .wordBreak(WordBreak.BREAK_WORD)
        .lineBreakStrategy(LineBreakStrategy.HIGH_QUALITY)
        .textOverflow({ overflow: TextOverflow.Clip })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  private HorizontalJudgementBlock() {
    Column() {
      Text('判断结果')
        .fontSize(CompactReviewTextStyle.judgementLabelSize)
        .fontWeight(FontWeight.Medium)
        .fontColor('#66707C')
        .lineHeight(CompactReviewTextStyle.judgementLabelLineHeight)
        .width('100%')

      Text(this.getJudgementLabel())
        .fontSize(CompactReviewTextStyle.judgementSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getJudgementLabel() === '成立'
          ? '#56745A'
          : (this.getJudgementLabel() === '不成立' ? '#87645E' : '#5E6B78'))
        .lineHeight(CompactReviewTextStyle.judgementLineHeight)
        .margin({ top: EXPORT_HORIZONTAL_JUDGEMENT_TOP_GAP })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding(EXPORT_HORIZONTAL_JUDGEMENT_PADDING)
    .width('100%')
    .backgroundColor('#F6F2EA')
    .borderRadius(EXPORT_HORIZONTAL_JUDGEMENT_RADIUS)
    .border({ width: 1, color: '#EEE6DA' })
  }

  @Builder
  private HorizontalReviewMeta() {
    Column() {
      Text('复盘信息')
        .fontSize(CompactReviewTextStyle.labelSize)
        .fontWeight(FontWeight.Medium)
        .fontColor(ReviewCardStyleTokens.labelColor)
        .lineHeight(CompactReviewTextStyle.labelLineHeight)
        .width('100%')

      if (this.hasValue(this.reviewerName)) {
        Text(`复盘人 · ${normalizeExportText(this.reviewerName)}`)
          .fontSize(CompactReviewTextStyle.labelSize)
          .fontColor('#7F8791')
          .lineHeight(CompactReviewTextStyle.labelLineHeight)
          .margin({ top: CompactReviewTextStyle.valueTopGap })
          .width('100%')
      }

      Text(formatReviewTime(this.document.updatedAt))
        .fontSize(CompactReviewTextStyle.labelSize)
        .fontColor('#7F8791')
        .lineHeight(CompactReviewTextStyle.labelLineHeight)
        .margin({ top: this.hasValue(this.reviewerName) ? 2 : CompactReviewTextStyle.valueTopGap })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  private HorizontalInfoLayout() {
    Row({ space: EXPORT_HORIZONTAL_COLUMN_GAP }) {
      Column({ space: EXPORT_HORIZONTAL_SECTION_GAP }) {
        this.HorizontalPanelTitle('观看过程')

        if (this.hasValue(this.document.content.visualFocus)) {
          this.HorizontalSection('视觉落点', this.document.content.visualFocus)
        }

        if (this.hasValue(this.document.content.visualPath)) {
          this.HorizontalSection('视线路径', this.document.content.visualPath)
        }

        if (this.hasValue(this.document.content.visibleFacts)) {
          this.HorizontalSection('画面事实', this.document.content.visibleFacts)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width(`${EXPORT_HORIZONTAL_LEFT_COLUMN_RATIO * 100}%`)

      Column({ space: EXPORT_HORIZONTAL_SECTION_GAP }) {
        this.HorizontalPanelTitle('判断摘要')
        this.HorizontalJudgementBlock()

        if (this.hasValue(this.document.content.coreRelation)) {
          this.HorizontalSection('最强关系', this.document.content.coreRelation)
        }

        this.HorizontalSection(
          '卡点',
          this.hasValue(this.document.content.currentBlocker) ? this.document.content.currentBlocker : '暂无明显卡点'
        )

        this.HorizontalReviewMeta()
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
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

      Column() {
        ReviewCardTitle({
          title: this.document.content.title,
          titleSize: CompactReviewTextStyle.titleSize,
          titleLineHeight: CompactReviewTextStyle.titleLineHeight
        })

        if (this.isHorizontalLayout()) {
          Column() {
            this.HorizontalInfoLayout()
          }
          .width('100%')
            .margin({ top: EXPORT_HORIZONTAL_TITLE_BOTTOM_GAP })
        } else {
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
