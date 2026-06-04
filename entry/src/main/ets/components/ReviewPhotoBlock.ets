import { hasDisplayableImageUri, getImageRatioLabel } from '../utils/ImageLayoutUtils';

@Component
export struct ReviewPhotoBlock {
  @Prop imageUri: string = '';
  @Prop imageWidth: number = 1600;
  @Prop imageHeight: number = 1000;
  @Prop aspectRatioValue: number = 1.6;
  @Prop compact: boolean = false;
  @Prop cornerRadius: number = 7;
  @State loadFailed: boolean = false;

  @Builder
  Placeholder() {
    Column() {
      Text(hasDisplayableImageUri(this.imageUri) && this.loadFailed ? '图片加载失败' : getImageRatioLabel(this.imageWidth, this.imageHeight))
        .fontSize(this.compact ? 14 : 18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F2329')
      Text(hasDisplayableImageUri(this.imageUri) && this.loadFailed ? '请返回重新选择照片' : `${this.imageWidth} x ${this.imageHeight}`)
        .fontSize(12)
        .fontColor('#68707D')
        .margin({ top: 6 })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor('#DCE7E1')
  }

  build() {
    Stack() {
      if (hasDisplayableImageUri(this.imageUri) && !this.loadFailed) {
        Image(this.imageUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
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
    .backgroundColor('#DCE7E1')
  }
}
