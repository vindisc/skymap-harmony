import {
  ExifPayload,
  ExifSource,
  isExifPayloadEmpty,
  normalizeExifPayload
} from '../model/ExifPayloadModel';
import { createDefaultReviewCardDocument, ReviewCardDocument } from '../model/ReviewCardModel';
import { ExifReaderService } from '../services/ExifReaderService';
import { AppColors, AppMetrics, AppTypography } from './AppDesign';

enum ExifFieldKey {
  CAMERA_MAKE = 'cameraMake',
  CAMERA_MODEL = 'cameraModel',
  LENS_MAKE = 'lensMake',
  LENS_MODEL = 'lensModel',
  FOCAL_LENGTH = 'focalLength',
  APERTURE = 'aperture',
  SHUTTER = 'shutter',
  ISO = 'iso'
}

@Component
export struct ExifSheet {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop imageUri: string = '';
  @State currentExif: ExifPayload = normalizeExifPayload(undefined);
  @State errorMessage: string = '';
  @State isReading: boolean = false;
  onUpdate: (nextExif: ExifPayload) => void = () => {};
  onClose: () => void = () => {};

  aboutToAppear(): void {
    this.currentExif = normalizeExifPayload(this.document.exif);
    if (this.document.exif === undefined || isExifPayloadEmpty(this.currentExif)) {
      this.reloadAll();
    }
  }

  private resolveFieldValue(field: ExifFieldKey): string {
    if (field === ExifFieldKey.CAMERA_MAKE) {
      return this.currentExif.cameraMake;
    }
    if (field === ExifFieldKey.CAMERA_MODEL) {
      return this.currentExif.cameraModel;
    }
    if (field === ExifFieldKey.LENS_MAKE) {
      return this.currentExif.lensMake;
    }
    if (field === ExifFieldKey.LENS_MODEL) {
      return this.currentExif.lensModel;
    }
    if (field === ExifFieldKey.FOCAL_LENGTH) {
      return this.currentExif.focalLength;
    }
    if (field === ExifFieldKey.APERTURE) {
      return this.currentExif.aperture;
    }
    if (field === ExifFieldKey.SHUTTER) {
      return this.currentExif.shutter;
    }
    return this.currentExif.iso;
  }

  private assignField(payload: ExifPayload, field: ExifFieldKey, value: string): void {
    if (field === ExifFieldKey.CAMERA_MAKE) {
      payload.cameraMake = value;
    } else if (field === ExifFieldKey.CAMERA_MODEL) {
      payload.cameraModel = value;
    } else if (field === ExifFieldKey.LENS_MAKE) {
      payload.lensMake = value;
    } else if (field === ExifFieldKey.LENS_MODEL) {
      payload.lensModel = value;
    } else if (field === ExifFieldKey.FOCAL_LENGTH) {
      payload.focalLength = value;
    } else if (field === ExifFieldKey.APERTURE) {
      payload.aperture = value;
    } else if (field === ExifFieldKey.SHUTTER) {
      payload.shutter = value;
    } else {
      payload.iso = value;
    }
  }

  private emitUpdate(nextExif: ExifPayload): void {
    this.currentExif = normalizeExifPayload(nextExif);
    this.onUpdate(normalizeExifPayload(nextExif));
  }

  private updateField(field: ExifFieldKey, value: string): void {
    const nextExif: ExifPayload = normalizeExifPayload(this.currentExif);
    this.assignField(nextExif, field, value);
    if (nextExif.manuallyOverridden.indexOf(field) < 0) {
      nextExif.manuallyOverridden.push(field);
    }
    nextExif.source = nextExif.source === ExifSource.MANUAL ? ExifSource.MANUAL : ExifSource.MIXED;
    this.errorMessage = '';
    this.emitUpdate(nextExif);
  }

  private async reloadField(field: ExifFieldKey): Promise<void> {
    this.isReading = true;
    try {
      const autoExif: ExifPayload = await ExifReaderService.read(this.imageUri);
      const value: string = this.resolvePayloadField(autoExif, field);
      if (value.length === 0) {
        this.errorMessage = '无法读取 EXIF · 手动填写';
        return;
      }
      const nextExif: ExifPayload = normalizeExifPayload(this.currentExif);
      this.assignField(nextExif, field, value);
      nextExif.manuallyOverridden = nextExif.manuallyOverridden.filter((key: string): boolean => key !== field);
      nextExif.source = nextExif.manuallyOverridden.length === 0 ? ExifSource.AUTO : ExifSource.MIXED;
      this.errorMessage = '';
      this.emitUpdate(nextExif);
    } catch (error) {
      this.errorMessage = '无法读取 EXIF · 手动填写';
    } finally {
      this.isReading = false;
    }
  }

  private resolvePayloadField(payload: ExifPayload, field: ExifFieldKey): string {
    if (field === ExifFieldKey.CAMERA_MAKE) {
      return payload.cameraMake;
    }
    if (field === ExifFieldKey.CAMERA_MODEL) {
      return payload.cameraModel;
    }
    if (field === ExifFieldKey.LENS_MAKE) {
      return payload.lensMake;
    }
    if (field === ExifFieldKey.LENS_MODEL) {
      return payload.lensModel;
    }
    if (field === ExifFieldKey.FOCAL_LENGTH) {
      return payload.focalLength;
    }
    if (field === ExifFieldKey.APERTURE) {
      return payload.aperture;
    }
    if (field === ExifFieldKey.SHUTTER) {
      return payload.shutter;
    }
    return payload.iso;
  }

  private async reloadAll(): Promise<void> {
    this.isReading = true;
    try {
      const autoExif: ExifPayload = await ExifReaderService.read(this.imageUri);
      if (isExifPayloadEmpty(autoExif)) {
        this.errorMessage = '无法读取 EXIF · 手动填写';
        return;
      }
      autoExif.source = ExifSource.AUTO;
      autoExif.manuallyOverridden = [];
      this.errorMessage = '';
      this.emitUpdate(autoExif);
    } catch (error) {
      this.errorMessage = '无法读取 EXIF · 手动填写';
    } finally {
      this.isReading = false;
    }
  }

  @Builder
  FieldRow(label: string, field: ExifFieldKey) {
    Row({ space: AppMetrics.space8 }) {
      Text(label)
        .fontFamily('NotoSansSC-Regular')
        .fontSize(AppTypography.inputLabel)
        .fontColor(AppColors.secondaryText)
        .width(88)

      TextInput({ text: this.resolveFieldValue(field), placeholder: '手动填写' })
        .height(AppMetrics.controlHeight)
        .fontSize(AppTypography.inputText)
        .fontColor(AppColors.text)
        .placeholderColor(AppColors.placeholderText)
        .backgroundColor(AppColors.surfaceTint)
        .borderRadius(AppMetrics.inputRadius)
        .padding({ left: AppMetrics.space12, right: AppMetrics.space12 })
        .layoutWeight(1)
        .onChange((value: string) => {
          this.updateField(field, value);
        })

      Button('↻')
        .fontFamily('NotoSansSC-Regular')
        .fontSize(AppTypography.buttonText)
        .fontColor(AppColors.primary)
        .width(AppMetrics.controlHeight)
        .height(AppMetrics.controlHeight)
        .backgroundColor(AppColors.primarySoft)
        .borderRadius(AppMetrics.buttonRadius)
        .enabled(!this.isReading)
        .onClick(() => {
          this.reloadField(field);
        })
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
  }

  build() {
    Column({ space: AppMetrics.space16 }) {
      Row() {
        Text('EXIF')
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

      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontFamily('NotoSansSC-Regular')
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.danger)
          .width('100%')
      }

      Scroll() {
        Column({ space: AppMetrics.space12 }) {
          this.FieldRow('相机品牌', ExifFieldKey.CAMERA_MAKE)
          this.FieldRow('相机型号', ExifFieldKey.CAMERA_MODEL)
          this.FieldRow('镜头品牌', ExifFieldKey.LENS_MAKE)
          this.FieldRow('镜头型号', ExifFieldKey.LENS_MODEL)
          this.FieldRow('焦距', ExifFieldKey.FOCAL_LENGTH)
          this.FieldRow('光圈', ExifFieldKey.APERTURE)
          this.FieldRow('快门', ExifFieldKey.SHUTTER)
          this.FieldRow('感光度', ExifFieldKey.ISO)
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')

      Button(this.isReading ? '读取中…' : '全部重读')
        .fontFamily('NotoSansSC-Bold')
        .fontSize(AppTypography.buttonText)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.onPrimary)
        .width('100%')
        .height(AppMetrics.controlHeight)
        .backgroundColor(this.isReading ? AppColors.primaryDisabled : AppColors.primary)
        .borderRadius(AppMetrics.buttonRadius)
        .enabled(!this.isReading)
        .onClick(() => {
          this.reloadAll();
        })
    }
    .width('100%')
    .height('100%')
    .padding(AppMetrics.cardPadding)
    .backgroundColor(AppColors.surface)
  }
}
