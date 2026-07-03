export enum PendingReviewPhotoStatus {
  PENDING = 'pending',
  REVIEWED = 'reviewed'
}

export enum PendingReviewPhotoOrientation {
  HORIZONTAL = 'horizontal',
  VERTICAL = 'vertical',
  SQUARE = 'square',
  UNKNOWN = 'unknown'
}

export interface PendingReviewPhoto {
  id: string;
  photoUri: string;
  fileName: string;
  width: number;
  height: number;
  orientation: string;
  importTime: number;
  status: string;
  linkedReviewId: string;
}

export function createPendingReviewPhoto(
  photoUri: string,
  fileName: string,
  width: number,
  height: number,
  orientation: string,
  importTime: number = Date.now()
): PendingReviewPhoto {
  const randomPart: string = Math.floor(Math.random() * 100000000).toString(36);
  return {
    id: `pending_${importTime}_${randomPart}`,
    photoUri: photoUri,
    fileName: fileName,
    width: width,
    height: height,
    orientation: orientation,
    importTime: importTime,
    status: PendingReviewPhotoStatus.PENDING,
    linkedReviewId: ''
  };
}

export function normalizePendingReviewPhoto(raw: PendingReviewPhoto): PendingReviewPhoto {
  return {
    id: typeof raw.id === 'string' && raw.id.length > 0 ? raw.id : createPendingReviewPhoto('', '', 0, 0, PendingReviewPhotoOrientation.UNKNOWN).id,
    photoUri: typeof raw.photoUri === 'string' ? raw.photoUri : '',
    fileName: typeof raw.fileName === 'string' ? raw.fileName : '',
    width: typeof raw.width === 'number' && raw.width > 0 ? raw.width : 1600,
    height: typeof raw.height === 'number' && raw.height > 0 ? raw.height : 1000,
    orientation: typeof raw.orientation === 'string' && raw.orientation.length > 0 ? raw.orientation : PendingReviewPhotoOrientation.UNKNOWN,
    importTime: typeof raw.importTime === 'number' && raw.importTime > 0 ? raw.importTime : Date.now(),
    status: raw.status === PendingReviewPhotoStatus.REVIEWED ? PendingReviewPhotoStatus.REVIEWED : PendingReviewPhotoStatus.PENDING,
    linkedReviewId: typeof raw.linkedReviewId === 'string' ? raw.linkedReviewId : ''
  };
}
