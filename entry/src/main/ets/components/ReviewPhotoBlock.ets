import { hasDisplayableImageUri } from '../utils/ImageLayoutUtils';
import { AppColors, AppMetrics, AppTypography } from './AppDesign';

@Component
export struct ReviewPhotoBlock {
  @Prop imageUri: string = '';
  @Prop imageWidth: number = 1600;
  @Prop imageHeight: number = 1000;
  @Prop imageSizeFallbackUsed: boolean = false;
  @Prop aspectRatioValue: number = 1.6;
  @Prop compact: boolean = false;
  @Prop cornerRadius: number = 7;
  @Prop fitMode: ImageFit = ImageFit.Contain;
  @State loadFailed: boolean = false;

  @Builder
  Placeholder() {
    Column({ space: 4 }) {
      Text(hasDisplayableImageUri(this.imageUri) && this.loadFailed ? '照片暂不可见' : '照片')
        .fontSize(this.compact ? AppTypography.caption : AppTypography.body)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.secondaryText)
      if (hasDisplayableImageUri(this.imageUri) && this.loadFailed) {
        Text('可稍后重试')
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.mutedText)
      } else if (this.imageSizeFallbackUsed) {
        Text('信息不可用')
          .fontSize(AppTypography.caption)
          .fontColor(AppColors.mutedText)
      }
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.surfaceMuted)
  }

  build() {
    Stack() {
      if (hasDisplayableImageUri(this.imageUri) && !this.loadFailed) {
        Image(this.imageUri)
          .width('100%')
          .height('100%')
          .objectFit(this.fitMode)
          .onError(() => {
            this.loadFailed = true;
          })
      } else {
        this.Placeholder()
      }
    }
    .width('100%')
    .aspectRatio(this.aspectRatioValue)
    .borderRadius(this.cornerRadius)
    .clip(true)
    .backgroundColor(AppColors.surfaceMuted)
  }
}
