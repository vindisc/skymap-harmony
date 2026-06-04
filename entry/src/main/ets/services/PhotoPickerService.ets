import photoAccessHelper from '@ohos.file.photoAccessHelper';
import image from '@ohos.multimedia.image';

export interface PickedPhotoResult {
  success: boolean;
  cancelled: boolean;
  imageUri: string;
  imageWidth: number;
  imageHeight: number;
  message: string;
}

const FALLBACK_IMAGE_WIDTH: number = 1600;
const FALLBACK_IMAGE_HEIGHT: number = 1000;

function emptyResult(cancelled: boolean, message: string): PickedPhotoResult {
  return {
    success: false,
    cancelled: cancelled,
    imageUri: '',
    imageWidth: FALLBACK_IMAGE_WIDTH,
    imageHeight: FALLBACK_IMAGE_HEIGHT,
    message: message
  };
}

async function resolveImageSize(imageUri: string): Promise<image.Size> {
  const source: image.ImageSource = image.createImageSource(imageUri);
  try {
    const imageInfo: image.ImageInfo = await source.getImageInfo();
    return imageInfo.size;
  } finally {
    await source.release();
  }
}

export async function pickSinglePhoto(): Promise<PickedPhotoResult> {
  try {
    const picker = new photoAccessHelper.PhotoViewPicker();
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;

    const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
    if (result.photoUris.length <= 0) {
      return emptyResult(true, '未选择照片');
    }

    const imageUri: string = result.photoUris[0];
    try {
      const size: image.Size = await resolveImageSize(imageUri);
      if (size.width > 0 && size.height > 0) {
        return {
          success: true,
          cancelled: false,
          imageUri: imageUri,
          imageWidth: size.width,
          imageHeight: size.height,
          message: ''
        };
      }
    } catch (error) {
      // TODO: 部分相册 URI 在当前 SDK/设备上可能无法直接解码宽高；这里先用横图兜底，后续可通过 photoAccessHelper.getAssets 读取媒体元数据。
      return {
        success: true,
        cancelled: false,
        imageUri: imageUri,
        imageWidth: FALLBACK_IMAGE_WIDTH,
        imageHeight: FALLBACK_IMAGE_HEIGHT,
        message: '已选择照片，但暂时无法读取宽高'
      };
    }

    return {
      success: true,
      cancelled: false,
      imageUri: imageUri,
      imageWidth: FALLBACK_IMAGE_WIDTH,
      imageHeight: FALLBACK_IMAGE_HEIGHT,
      message: '已选择照片，但宽高为空'
    };
  } catch (error) {
    return emptyResult(false, '无法打开系统相册，请稍后重试');
  }
}
