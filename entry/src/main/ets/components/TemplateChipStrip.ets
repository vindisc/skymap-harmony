import {
  resolveTemplate,
  TemplateDescriptor,
  TemplateId,
  TemplateLevel
} from '../model/TemplateModel';
import { AppColors, AppMetrics, AppTypography } from './AppDesign';

const TEMPLATE_CHIP_WIDTH: number = 88;
const TEMPLATE_CHIP_HEIGHT: number = 88;
const TEMPLATE_CHIP_PREVIEW_HEIGHT: number = 48;
const TEMPLATE_CHIP_LABEL_LINE_HEIGHT: number = 16;
const TEMPLATE_CHIP_PADDING: number = 4;

const VISIBLE_TEMPLATE_IDS: Array<TemplateId> = [
  TemplateId.WHITE_EQUAL,
  TemplateId.META_BOTTOM,
  TemplateId.SIGNATURE_OVERLAY,
  TemplateId.ADAPTIVE_REVIEW_CARD
];

function listVisibleTemplates(level: TemplateLevel): Array<TemplateDescriptor> {
  return VISIBLE_TEMPLATE_IDS
    .map((id: TemplateId): TemplateDescriptor => resolveTemplate(id))
    .filter((descriptor: TemplateDescriptor): boolean => descriptor.level === level);
}

@Component
export struct TemplateChipStrip {
  @Prop currentLevel: TemplateLevel = TemplateLevel.L3_REVIEW;
  @Prop currentCanonicalTemplateId: string = TemplateId.ADAPTIVE_REVIEW_CARD;
  onTemplateTap: (templateId: string) => void = () => {};

  build() {
    Scroll() {
      Row({ space: AppMetrics.space12 }) {
        ForEach(listVisibleTemplates(this.currentLevel), (descriptor: TemplateDescriptor) => {
          Column({ space: AppMetrics.space8 }) {
            Column() {
              Column()
                .width(28)
                .height(38)
                .borderRadius(4)
                .backgroundColor(descriptor.defaults.frame.backgroundColorHex)
                .border({ width: 1, color: AppColors.border })
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
            .height(TEMPLATE_CHIP_PREVIEW_HEIGHT)
            .borderRadius(AppMetrics.space8)
            .backgroundColor(AppColors.surfaceTint)

            Text(descriptor.displayName)
              .fontFamily(this.currentCanonicalTemplateId === descriptor.id
                ? 'NotoSansSC-Bold'
                : 'NotoSansSC-Regular')
              .fontSize(AppTypography.meta)
              .fontWeight(this.currentCanonicalTemplateId === descriptor.id ? FontWeight.Bold : FontWeight.Regular)
              .fontColor(this.currentCanonicalTemplateId === descriptor.id
                ? AppColors.primary
                : AppColors.secondaryText)
              .lineHeight(TEMPLATE_CHIP_LABEL_LINE_HEIGHT)
              .textAlign(TextAlign.Center)
              .width('100%')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width(TEMPLATE_CHIP_WIDTH)
          .height(TEMPLATE_CHIP_HEIGHT)
          .padding(TEMPLATE_CHIP_PADDING)
          .borderRadius(AppMetrics.inputRadius)
          .border({
            width: this.currentCanonicalTemplateId === descriptor.id ? 2 : 1,
            color: this.currentCanonicalTemplateId === descriptor.id ? AppColors.primary : AppColors.border
          })
          .backgroundColor(AppColors.surface)
          .onClick(() => {
            if (this.currentCanonicalTemplateId !== descriptor.id) {
              this.onTemplateTap(descriptor.id);
            }
          })
        }, (descriptor: TemplateDescriptor) => descriptor.id)
      }
      .padding({ left: AppMetrics.pagePadding, right: AppMetrics.pagePadding })
      .height(TEMPLATE_CHIP_HEIGHT)
    }
    .width('100%')
    .height(TEMPLATE_CHIP_HEIGHT)
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}
