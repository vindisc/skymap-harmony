import { normalizeExifPayload } from '../model/ExifPayloadModel';
import { normalizeFrameConfig, FrameConfigSpec } from '../model/FrameConfigModel';
import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { resolveTemplate, TemplateDescriptor, TemplateLevel } from '../model/TemplateModel';
import { hasDisplayableImageUri } from '../utils/ImageLayoutUtils';
import { AppColors, AppTypography } from './AppDesign';

interface FramePreviewGeometry {
  canvasWidth: number;
  canvasHeight: number;
  outerPadding: number;
  innerPadding: number;
  photoWidth: number;
  photoHeight: number;
  bottomBarHeight: number;
  cornerRadius: number;
  titleFontSize: number;
  bodyFontSize: number;
}

@Component
export struct FrameTemplatePreview {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop maxWidth: number = 360;
  @Prop maxHeight: number = 286;
  @State loadFailed: boolean = false;

  private getDescriptor(): TemplateDescriptor {
    return resolveTemplate(this.document.config.templateId);
  }

  private getFrame(): FrameConfigSpec {
    const descriptor: TemplateDescriptor = this.getDescriptor();
    return normalizeFrameConfig(this.document.config.frame, descriptor.defaults.frame);
  }

  private getGeometry(): FramePreviewGeometry {
    const frame: FrameConfigSpec = this.getFrame();
    const sourceWidth: number = Math.max(1, this.document.imageWidth);
    const sourceHeight: number = Math.max(1, this.document.imageHeight);
    const longEdge: number = Math.max(sourceWidth, sourceHeight);
    const shortEdge: number = Math.min(sourceWidth, sourceHeight);
    const sourceOuterPadding: number = longEdge * frame.outerPaddingRatio;
    const isMetaTemplate: boolean = this.getDescriptor().level === TemplateLevel.L1_META;
    const sourceInnerPadding: number = isMetaTemplate ? longEdge * frame.innerPaddingRatio : 0;
    const sourceTitleFont: number = isMetaTemplate ? shortEdge * frame.titleFontRatio : 0;
    const sourceBodyFont: number = isMetaTemplate ? shortEdge * frame.bodyFontRatio : 0;
    const sourceBottomBarHeight: number = isMetaTemplate ? sourceTitleFont * 2.4 : 0;
    const sourceCanvasWidth: number = sourceWidth + sourceOuterPadding * 2;
    const sourceCanvasHeight: number = sourceHeight + sourceOuterPadding * 2 +
      sourceInnerPadding + sourceBottomBarHeight;
    const widthScale: number = this.maxWidth / sourceCanvasWidth;
    const heightScale: number = this.maxHeight / sourceCanvasHeight;
    const scale: number = Math.min(widthScale, heightScale);
    return {
      canvasWidth: sourceCanvasWidth * scale,
      canvasHeight: sourceCanvasHeight * scale,
      outerPadding: sourceOuterPadding * scale,
      innerPadding: sourceInnerPadding * scale,
      photoWidth: sourceWidth * scale,
      photoHeight: sourceHeight * scale,
      bottomBarHeight: sourceBottomBarHeight * scale,
      cornerRadius: longEdge * frame.cornerRadiusRatio * scale,
      titleFontSize: Math.max(9, sourceTitleFont * scale),
      bodyFontSize: Math.max(9, sourceBodyFont * scale)
    };
  }

  private getMetaLeftText(): string {
    return normalizeExifPayload(this.document.exif).cameraModel;
  }

  private getMetaRightText(): string {
    const exif = normalizeExifPayload(this.document.exif);
    const values: Array<string> = [];
    if (exif.focalLength.length > 0) {
      values.push(exif.focalLength);
    }
    if (exif.aperture.length > 0) {
      values.push(exif.aperture);
    }
    if (exif.shutter.length > 0) {
      values.push(exif.shutter);
    }
    if (exif.iso.length > 0) {
      values.push(exif.iso);
    }
    return values.join(' ');
  }

  @Builder
  PhotoContent(geometry: FramePreviewGeometry) {
    if (hasDisplayableImageUri(this.document.imageUri) && !this.loadFailed) {
      Image(this.document.imageUri)
        .width(geometry.photoWidth)
        .height(geometry.photoHeight)
        .objectFit(ImageFit.Fill)
        .borderRadius(geometry.cornerRadius)
        .clip(true)
        .onError(() => {
          this.loadFailed = true;
        })
    } else {
      Column() {
        Text(this.loadFailed ? '照片暂不可见' : '照片')
          .fontFamily('NotoSansSC-Regular')
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.secondaryText)
      }
      .justifyContent(FlexAlign.Center)
      .width(geometry.photoWidth)
      .height(geometry.photoHeight)
      .backgroundColor(AppColors.surfaceMuted)
      .borderRadius(geometry.cornerRadius)
    }
  }

  @Builder
  MetaBar(geometry: FramePreviewGeometry) {
    Row({ space: Math.max(4, geometry.innerPadding) }) {
      Text(this.getMetaLeftText())
        .fontFamily('NotoSansSC-Bold')
        .fontSize(geometry.titleFontSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getFrame().textColorHex)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      Text(this.getMetaRightText())
        .fontFamily('NotoSansSC-Regular')
        .fontSize(geometry.bodyFontSize)
        .fontColor(this.getFrame().secondaryTextColorHex)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(VerticalAlign.Center)
    .width(Math.max(1, geometry.photoWidth - geometry.innerPadding * 2))
    .height(geometry.bottomBarHeight)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        this.PhotoContent(this.getGeometry())
      }
        .width(this.getGeometry().photoWidth)
        .height(this.getGeometry().photoHeight)
        .position({
          x: this.getGeometry().outerPadding,
          y: this.getGeometry().outerPadding
        })

      if (this.getDescriptor().level === TemplateLevel.L1_META) {
        Column() {
          this.MetaBar(this.getGeometry())
        }
          .width(Math.max(1, this.getGeometry().photoWidth - this.getGeometry().innerPadding * 2))
          .height(this.getGeometry().bottomBarHeight)
          .position({
            x: this.getGeometry().outerPadding + this.getGeometry().innerPadding,
            y: this.getGeometry().outerPadding + this.getGeometry().photoHeight + this.getGeometry().innerPadding
          })
      }
    }
    .width(this.getGeometry().canvasWidth)
    .height(this.getGeometry().canvasHeight)
    .backgroundColor(this.getFrame().backgroundColorHex)
    .border({ width: 1, color: '#1A000000' })
  }
}
