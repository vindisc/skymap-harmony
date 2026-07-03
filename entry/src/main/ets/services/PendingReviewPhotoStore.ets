import common from '@ohos.app.ability.common';
import relationalStore from '@ohos.data.relationalStore';
import {
  createPendingReviewPhoto,
  normalizePendingReviewPhoto,
  PendingReviewPhoto,
  PendingReviewPhotoOrientation,
  PendingReviewPhotoStatus
} from '../model/PendingReviewPhotoModel';
import { REVIEW_LIBRARY_RDB_NAME } from './ReviewCardRdbModel';
import { getImageRatioKind } from '../utils/ImageLayoutUtils';

const PENDING_REVIEW_PHOTO_TABLE: string = 'pending_review_photos';
const PENDING_REVIEW_RDB_CONFIG: relationalStore.StoreConfig = {
  name: REVIEW_LIBRARY_RDB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
};

const CREATE_PENDING_REVIEW_PHOTOS_TABLE_SQL: string = `
CREATE TABLE IF NOT EXISTS pending_review_photos (
  id TEXT PRIMARY KEY,
  photo_uri TEXT NOT NULL,
  file_name TEXT,
  width INTEGER,
  height INTEGER,
  orientation TEXT,
  import_time INTEGER NOT NULL,
  status TEXT NOT NULL,
  linked_review_id TEXT
)`;

const PENDING_REVIEW_PHOTO_INDEX_SQLS: Array<string> = [
  'CREATE INDEX IF NOT EXISTS idx_pending_review_photos_status ON pending_review_photos(status)',
  'CREATE INDEX IF NOT EXISTS idx_pending_review_photos_import_time ON pending_review_photos(import_time)',
  'CREATE INDEX IF NOT EXISTS idx_pending_review_photos_linked_review_id ON pending_review_photos(linked_review_id)'
];

export interface PendingReviewPhotoStats {
  pendingCount: number;
  reviewedCount: number;
  totalImportedCount: number;
}

export function createEmptyPendingReviewPhotoStats(): PendingReviewPhotoStats {
  return {
    pendingCount: 0,
    reviewedCount: 0,
    totalImportedCount: 0
  };
}

function getValue(resultSet: relationalStore.ResultSet, columnName: string): relationalStore.ValueType {
  return resultSet.getValue(resultSet.getColumnIndex(columnName));
}

function getStringValue(resultSet: relationalStore.ResultSet, columnName: string): string {
  const value: relationalStore.ValueType = getValue(resultSet, columnName);
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return `${value}`;
  }
  return '';
}

function getNumberValue(resultSet: relationalStore.ResultSet, columnName: string): number {
  const value: relationalStore.ValueType = getValue(resultSet, columnName);
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string') {
    const parsedValue: number = Number(value);
    return Number.isFinite(parsedValue) ? parsedValue : 0;
  }
  return 0;
}

function resolveFileName(photoUri: string): string {
  const normalizedPath: string = photoUri.replace(/\\/g, '/');
  const slashIndex: number = normalizedPath.lastIndexOf('/');
  const fileName: string = slashIndex >= 0 ? normalizedPath.slice(slashIndex + 1) : normalizedPath;
  return fileName.trim();
}

function resolveOrientation(width: number, height: number, fallbackUsed: boolean): string {
  const kind: string = getImageRatioKind(width, height, fallbackUsed);
  if (kind === 'horizontal') {
    return PendingReviewPhotoOrientation.HORIZONTAL;
  }
  if (kind === 'vertical') {
    return PendingReviewPhotoOrientation.VERTICAL;
  }
  if (kind === 'square') {
    return PendingReviewPhotoOrientation.SQUARE;
  }
  return PendingReviewPhotoOrientation.UNKNOWN;
}

function rowFromResultSet(resultSet: relationalStore.ResultSet): PendingReviewPhoto {
  return normalizePendingReviewPhoto({
    id: getStringValue(resultSet, 'id'),
    photoUri: getStringValue(resultSet, 'photo_uri'),
    fileName: getStringValue(resultSet, 'file_name'),
    width: getNumberValue(resultSet, 'width'),
    height: getNumberValue(resultSet, 'height'),
    orientation: getStringValue(resultSet, 'orientation'),
    importTime: getNumberValue(resultSet, 'import_time'),
    status: getStringValue(resultSet, 'status'),
    linkedReviewId: getStringValue(resultSet, 'linked_review_id')
  });
}

function toValuesBucket(photo: PendingReviewPhoto): relationalStore.ValuesBucket {
  const normalized: PendingReviewPhoto = normalizePendingReviewPhoto(photo);
  return {
    id: normalized.id,
    photo_uri: normalized.photoUri,
    file_name: normalized.fileName,
    width: normalized.width,
    height: normalized.height,
    orientation: normalized.orientation,
    import_time: normalized.importTime,
    status: normalized.status,
    linked_review_id: normalized.linkedReviewId
  };
}

export class PendingReviewPhotoStore {
  private static storePromise: Promise<relationalStore.RdbStore> | undefined = undefined;

  static async init(context: common.UIAbilityContext): Promise<void> {
    const store: relationalStore.RdbStore = await PendingReviewPhotoStore.getStore(context);
    await store.executeSql(CREATE_PENDING_REVIEW_PHOTOS_TABLE_SQL);
    for (let index = 0; index < PENDING_REVIEW_PHOTO_INDEX_SQLS.length; index += 1) {
      await store.executeSql(PENDING_REVIEW_PHOTO_INDEX_SQLS[index]);
    }
  }

  static async addPhoto(
    context: common.UIAbilityContext,
    photoUri: string,
    width: number,
    height: number,
    imageSizeFallbackUsed: boolean = false
  ): Promise<PendingReviewPhoto> {
    const store: relationalStore.RdbStore = await PendingReviewPhotoStore.getInitializedStore(context);
    const photo: PendingReviewPhoto = createPendingReviewPhoto(
      photoUri,
      resolveFileName(photoUri),
      width,
      height,
      resolveOrientation(width, height, imageSizeFallbackUsed)
    );
    await store.insert(
      PENDING_REVIEW_PHOTO_TABLE,
      toValuesBucket(photo),
      relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
    );
    return normalizePendingReviewPhoto(photo);
  }

  static async listPending(context: common.UIAbilityContext): Promise<Array<PendingReviewPhoto>> {
    const store: relationalStore.RdbStore = await PendingReviewPhotoStore.getInitializedStore(context);
    const resultSet: relationalStore.ResultSet = await store.querySql(
      `SELECT * FROM ${PENDING_REVIEW_PHOTO_TABLE} WHERE status = ? ORDER BY import_time DESC`,
      [PendingReviewPhotoStatus.PENDING]
    );
    const photos: Array<PendingReviewPhoto> = [];
    try {
      while (resultSet.goToNextRow()) {
        photos.push(rowFromResultSet(resultSet));
      }
    } finally {
      resultSet.close();
    }
    return photos;
  }

  static async getById(context: common.UIAbilityContext, id: string): Promise<PendingReviewPhoto | undefined> {
    const store: relationalStore.RdbStore = await PendingReviewPhotoStore.getInitializedStore(context);
    const resultSet: relationalStore.ResultSet = await store.querySql(
      `SELECT * FROM ${PENDING_REVIEW_PHOTO_TABLE} WHERE id = ? LIMIT 1`,
      [id]
    );
    try {
      if (!resultSet.goToFirstRow()) {
        return undefined;
      }
      return rowFromResultSet(resultSet);
    } finally {
      resultSet.close();
    }
  }

  static async countPending(context: common.UIAbilityContext): Promise<number> {
    const store: relationalStore.RdbStore = await PendingReviewPhotoStore.getInitializedStore(context);
    const resultSet: relationalStore.ResultSet = await store.querySql(
      `SELECT COUNT(1) AS total FROM ${PENDING_REVIEW_PHOTO_TABLE} WHERE status = ?`,
      [PendingReviewPhotoStatus.PENDING]
    );
    try {
      if (!resultSet.goToFirstRow()) {
        return 0;
      }
      return getNumberValue(resultSet, 'total');
    } finally {
      resultSet.close();
    }
  }

  static async getStats(context: common.UIAbilityContext): Promise<PendingReviewPhotoStats> {
    const store: relationalStore.RdbStore = await PendingReviewPhotoStore.getInitializedStore(context);
    const resultSet: relationalStore.ResultSet = await store.querySql(
      `SELECT COUNT(1) AS total_imported,
        SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) AS pending_total,
        SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) AS reviewed_total
        FROM ${PENDING_REVIEW_PHOTO_TABLE}`,
      [PendingReviewPhotoStatus.PENDING, PendingReviewPhotoStatus.REVIEWED]
    );
    try {
      if (!resultSet.goToFirstRow()) {
        return createEmptyPendingReviewPhotoStats();
      }
      return {
        pendingCount: getNumberValue(resultSet, 'pending_total'),
        reviewedCount: getNumberValue(resultSet, 'reviewed_total'),
        totalImportedCount: getNumberValue(resultSet, 'total_imported')
      };
    } finally {
      resultSet.close();
    }
  }

  static async markReviewed(context: common.UIAbilityContext, id: string, linkedReviewId: string): Promise<void> {
    const store: relationalStore.RdbStore = await PendingReviewPhotoStore.getInitializedStore(context);
    await store.executeSql(
      `UPDATE ${PENDING_REVIEW_PHOTO_TABLE} SET status = ?, linked_review_id = ? WHERE id = ?`,
      [PendingReviewPhotoStatus.REVIEWED, linkedReviewId, id]
    );
  }

  static async updateLinkedReviewId(context: common.UIAbilityContext, id: string, linkedReviewId: string): Promise<void> {
    const store: relationalStore.RdbStore = await PendingReviewPhotoStore.getInitializedStore(context);
    await store.executeSql(
      `UPDATE ${PENDING_REVIEW_PHOTO_TABLE} SET linked_review_id = ? WHERE id = ?`,
      [linkedReviewId, id]
    );
  }

  static async delete(context: common.UIAbilityContext, id: string): Promise<void> {
    const store: relationalStore.RdbStore = await PendingReviewPhotoStore.getInitializedStore(context);
    await store.executeSql(`DELETE FROM ${PENDING_REVIEW_PHOTO_TABLE} WHERE id = ?`, [id]);
  }

  private static async getInitializedStore(context: common.UIAbilityContext): Promise<relationalStore.RdbStore> {
    await PendingReviewPhotoStore.init(context);
    return PendingReviewPhotoStore.getStore(context);
  }

  private static async getStore(context: common.UIAbilityContext): Promise<relationalStore.RdbStore> {
    if (!PendingReviewPhotoStore.storePromise) {
      PendingReviewPhotoStore.storePromise = relationalStore.getRdbStore(context, PENDING_REVIEW_RDB_CONFIG);
    }
    return PendingReviewPhotoStore.storePromise;
  }
}
