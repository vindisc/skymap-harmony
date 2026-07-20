import { FrameConfigSpec, normalizeFrameConfig } from '../model/FrameConfigModel';
import {
  cloneReviewCardDocument,
  createDefaultReviewCardDocument,
  ReviewCardDocument
} from '../model/ReviewCardModel';
import { resolveTemplate, TemplateDescriptor, TemplateLevel } from '../model/TemplateModel';
import { applyTemplateToDocument } from '../utils/TemplateApply';
import { AppColors, AppMetrics, AppTypography } from './AppDesign';
import { ColorSwatchRow } from './ColorSwatchRow';

@Component
export struct FrameParamsSheet {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  onUpdate: (nextDocument: ReviewCardDocument) => void = () => {};
  onClose: () => void = () => {};

  private getDescriptor(): TemplateDescriptor {
    return resolveTemplate(this.document.config.templateId);
  }

  private getFrame(): FrameConfigSpec {
    return normalizeFrameConfig(this.document.config.frame, this.getDescriptor().defaults.frame);
  }

  private updateFrameValue(key: string, value: number): void {
    const nextFrame: FrameConfigSpec = this.getFrame();
    if (key === 'outerPaddingRatio') {
      nextFrame.outerPaddingRatio = value;
    } else if (key === 'innerPaddingRatio') {
      nextFrame.innerPaddingRatio = value;
    } else {
      nextFrame.cornerRadiusRatio = value;
    }
    this.emitFrameUpdate(nextFrame);
  }

  private updateBackgroundColor(color: string): void {
    const nextFrame: FrameConfigSpec = this.getFrame();
    nextFrame.backgroundColorHex = color;
    this.emitFrameUpdate(nextFrame);
  }

  private emitFrameUpdate(frame: FrameConfigSpec): void {
    const nextDocument: ReviewCardDocument = cloneReviewCardDocument(this.document);
    nextDocument.config.frame = frame;
    this.onUpdate(nextDocument);
  }

  private restoreDefaults(): void {
    this.onUpdate(applyTemplateToDocument(this.document, this.document.config.templateId));
  }

  @Builder
  RatioSlider(label: string, value: number, min: number, max: number, disabled: boolean, key: string) {
    Column({ space: AppMetrics.space8 }) {
      Row() {
        Text(label)
          .fontFamily('NotoSansSC-Regular')
          .fontSize(AppTypography.inputLabel)
          .fontColor(disabled ? AppColors.placeholderText : AppColors.secondaryText)
          .layoutWeight(1)

        Text(`${Math.round(value * 1000) / 10}%`)
          .fontFamily('NotoSansSC-Regular')
          .fontSize(AppTypography.meta)
          .fontColor(disabled ? AppColors.placeholderText : AppColors.text)
      }
      .width('100%')

      Slider({ value: value, min: min, max: max, step: 0.002 })
        .selectedColor(AppColors.primary)
        .trackColor(AppColors.border)
        .blockColor(AppColors.surface)
        .enabled(!disabled)
        .opacity(disabled ? 0.4 : 1)
        .onChange((nextValue: number) => {
          this.updateFrameValue(key, nextValue);
        })
    }
    .width('100%')
  }

  build() {
    Column({ space: AppMetrics.space16 }) {
      Row() {
        Text('边框参数')
          .fontFamily('NotoSansSC-Bold')
          .fontSize(AppTypography.sectionTitle)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.text)
          .layoutWeight(1)

        Button('关闭')
          .fontFamily('NotoSansSC-Regular')
          .fontSize(AppTypography.smallButtonText)
          .fontColor(AppColors.primary)
          .backgroundColor(AppColors.transparent)
          .onClick(() => {
            this.onClose();
          })
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')

      this.RatioSlider('外留白', this.getFrame().outerPaddingRatio, 0.010, 0.100, false, 'outerPaddingRatio')
      this.RatioSlider(
        '内留白',
        this.getFrame().innerPaddingRatio,
        0.000,
        0.030,
        this.getDescriptor().level === TemplateLevel.L0_FRAME,
        'innerPaddingRatio'
      )
      this.RatioSlider(
        '圆角',
        this.getFrame().cornerRadiusRatio,
        0.000,
        0.030,
        this.getDescriptor().level === TemplateLevel.L0_FRAME,
        'cornerRadiusRatio'
      )

      ColorSwatchRow({
        colors: this.getDescriptor().allowedBackgroundColors,
        currentColor: this.getFrame().backgroundColorHex,
        disabled: this.getDescriptor().allowedBackgroundColors.length <= 1,
        onChange: (color: string) => {
          this.updateBackgroundColor(color);
        }
      })

      Button('恢复当前模板默认值')
        .fontFamily('NotoSansSC-Bold')
        .fontSize(AppTypography.buttonText)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.primary)
        .width('100%')
        .height(AppMetrics.controlHeight)
        .borderRadius(AppMetrics.buttonRadius)
        .backgroundColor(AppColors.primarySoft)
        .onClick(() => {
          this.restoreDefaults();
        })
    }
    .width('100%')
    .padding(AppMetrics.cardPadding)
    .borderRadius({ topLeft: AppMetrics.cardRadius, topRight: AppMetrics.cardRadius })
    .backgroundColor(AppColors.surface)
  }
}
