import photoAccessHelper from '@ohos.file.photoAccessHelper';
import image from '@ohos.multimedia.image';
import fs from '@ohos.file.fs';
import { REVIEW_FLOW_IMPORT_FAILED_TEXT } from './ReviewFlowFeedback';

export interface PickedPhotoResult {
  success: boolean;
  cancelled: boolean;
  imageUri: string;
  imageWidth: number;
  imageHeight: number;
  imageSizeFallbackUsed: boolean;
  message: string;
}

const FALLBACK_IMAGE_WIDTH: number = 1600;
const FALLBACK_IMAGE_HEIGHT: number = 1000;

export interface DisplayImageSize {
  width: number;
  height: number;
}

function emptyResult(cancelled: boolean, message: string): PickedPhotoResult {
  return {
    success: false,
    cancelled: cancelled,
    imageUri: '',
    imageWidth: FALLBACK_IMAGE_WIDTH,
    imageHeight: FALLBACK_IMAGE_HEIGHT,
    imageSizeFallbackUsed: false,
    message: message
  };
}

function shouldSwapOrientation(orientation: string): boolean {
  const normalized = orientation.trim().toLowerCase();
  return normalized === '5'
    || normalized === '6'
    || normalized === '7'
    || normalized === '8'
    || normalized === 'left-top'
    || normalized === 'right-top'
    || normalized === 'right-bottom'
    || normalized === 'left-bottom';
}

async function readDisplayImageSize(source: image.ImageSource): Promise<DisplayImageSize> {
  try {
    const imageInfo: image.ImageInfo = await source.getImageInfo();
    let width = imageInfo.size.width;
    let height = imageInfo.size.height;
    try {
      const orientation = await source.getImageProperty(image.PropertyKey.ORIENTATION);
      if (shouldSwapOrientation(orientation)) {
        const originalWidth = width;
        width = height;
        height = originalWidth;
      }
    } catch (error) {
    }
    return {
      width: width,
      height: height
    };
  } finally {
    await source.release();
  }
}

async function resolveDisplayImageSizeByUri(imageUri: string): Promise<DisplayImageSize> {
  const source: image.ImageSource = image.createImageSource(imageUri);
  return readDisplayImageSize(source);
}

async function resolveDisplayImageSizeByFd(imageUri: string): Promise<DisplayImageSize> {
  const file: fs.File = fs.openSync(imageUri, fs.OpenMode.READ_ONLY);
  try {
    const source: image.ImageSource = image.createImageSource(file.fd);
    return await readDisplayImageSize(source);
  } finally {
    fs.closeSync(file);
  }
}

export async function resolveDisplayImageSize(imageUri: string): Promise<DisplayImageSize> {
  try {
    return await resolveDisplayImageSizeByUri(imageUri);
  } catch (error) {
    return await resolveDisplayImageSizeByFd(imageUri);
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
      const size: DisplayImageSize = await resolveDisplayImageSize(imageUri);
      if (size.width > 0 && size.height > 0) {
        return {
          success: true,
          cancelled: false,
          imageUri: imageUri,
          imageWidth: size.width,
          imageHeight: size.height,
          imageSizeFallbackUsed: false,
          message: ''
        };
      }
    } catch (error) {
      return {
        success: true,
        cancelled: false,
        imageUri: imageUri,
        imageWidth: FALLBACK_IMAGE_WIDTH,
        imageHeight: FALLBACK_IMAGE_HEIGHT,
        imageSizeFallbackUsed: true,
        message: ''
      };
    }

    return {
      success: true,
      cancelled: false,
      imageUri: imageUri,
      imageWidth: FALLBACK_IMAGE_WIDTH,
      imageHeight: FALLBACK_IMAGE_HEIGHT,
      imageSizeFallbackUsed: true,
      message: ''
    };
  } catch (error) {
    return emptyResult(false, REVIEW_FLOW_IMPORT_FAILED_TEXT);
  }
}
