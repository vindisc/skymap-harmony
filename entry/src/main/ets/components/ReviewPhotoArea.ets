import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewPhotoBlock } from './ReviewPhotoBlock';

@Component
export struct ReviewPhotoArea {
  @Prop imageUri: string = '';
  @Prop imageWidth: number = 1600;
  @Prop imageHeight: number = 1000;
  @Prop aspectRatioValue: number = 1.6;
  @Prop compact: boolean = false;

  build() {
    ReviewPhotoBlock({
      imageUri: this.imageUri,
      imageWidth: this.imageWidth,
      imageHeight: this.imageHeight,
      aspectRatioValue: this.aspectRatioValue,
      compact: this.compact,
      cornerRadius: ReviewCardStyleTokens.photoRadius,
      fitMode: ImageFit.Contain
    })
  }
}
