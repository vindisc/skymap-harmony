import { hasDisplayableImageUri } from '../utils/ImageLayoutUtils';

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
    Column() {
      Text(hasDisplayableImageUri(this.imageUri) && this.loadFailed ? '图片加载失败' : '照片预览')
        .fontSize(this.compact ? 14 : 18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F2329')
      if (hasDisplayableImageUri(this.imageUri) && this.loadFailed) {
        Text('请重新选择照片')
          .fontSize(12)
          .fontColor('#68707D')
          .margin({ top: 6 })
      } else if (this.imageSizeFallbackUsed) {
        Text('暂时无法读取照片信息')
          .fontSize(12)
          .fontColor('#68707D')
          .margin({ top: 6 })
      }
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor('#E9E5DC')
  }

  build() {
    Stack() {
      if (hasDisplayableImageUri(this.imageUri) && !this.loadFailed) {
        Image(this.imageUri)
          .width('100%')
          .height('100%')
          .objectFit(this.fitMode)
          .syncLoad(true)
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
    .backgroundColor('#E9E5DC')
  }
}
