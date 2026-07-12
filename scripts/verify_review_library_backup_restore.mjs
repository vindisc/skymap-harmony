import crypto from 'node:crypto';
import fs from 'node:fs';

const backupSource = fs.readFileSync(
  'entry/src/main/ets/services/ReviewLibraryBackupService.ets',
  'utf8'
);
const rdbSource = fs.readFileSync(
  'entry/src/main/ets/services/ReviewCardRdbService.ets',
  'utf8'
);
const historySource = fs.readFileSync(
  'entry/src/main/ets/services/ReviewCardHistoryService.ets',
  'utf8'
);
const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');
const debugLaunchSource = fs.readFileSync(
  'entry/src/main/ets/services/DebugLaunchScenarioService.ets',
  'utf8'
);

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function extractMethodBody(source, signature) {
  const start = source.indexOf(signature);
  assert(start >= 0, `缺少方法：${signature}`);
  if (start < 0) {
    return '';
  }
  const braceStart = source.indexOf('{', start);
  let depth = 0;
  for (let index = braceStart; index < source.length; index += 1) {
    if (source[index] === '{') {
      depth += 1;
    } else if (source[index] === '}') {
      depth -= 1;
      if (depth === 0) {
        return source.slice(braceStart, index + 1);
      }
    }
  }
  return source.slice(braceStart);
}

assert(backupSource.includes("'JianYuReviewLibraryBackup'"), '备份必须有稳定 schemaName。');
assert(backupSource.includes("REVIEW_LIBRARY_BACKUP_SCHEMA_VERSION: string = 'v2'"), '新备份必须使用包含原图的 v2。');
assert(backupSource.includes("REVIEW_LIBRARY_BACKUP_LEGACY_SCHEMA_VERSION: string = 'v1'"), '恢复必须兼容 v1 备份。');
assert(backupSource.includes("REVIEW_LIBRARY_BACKUP_EXTENSION: string = 'jybackup'"), '备份必须使用独立扩展名。');
assert(backupSource.includes("'SHA-256'"), '备份必须使用 SHA-256 完整性校验。');
assert(backupSource.includes('DocumentViewPicker(context)'), '备份和恢复必须通过系统文件选择器。');
assert(backupSource.includes('documentPicker.save({'), '备份必须保存到用户选择的外部文件。');
assert(backupSource.includes('documentPicker.select({'), '恢复必须由用户选择备份文件。');
assert(backupSource.includes('maxSelectNumber: REVIEW_LIBRARY_BACKUP_MAX_SELECT_NUMBER'), '恢复必须支持多选备份。');
assert(backupSource.includes('new Map<string, ReviewLibraryBackupRecordV1>()'), '多份备份必须按复盘 ID 去重合并。');
assert(backupSource.includes('mergeBackupRecord(existing, record)'), '重复复盘必须合并最新内容和可用原图。');
assert(!backupSource.includes('fileSuffixFilters:'), '恢复选择器不得用自定义后缀过滤隐藏备份文件。');
assert(backupSource.includes('savedText !== envelopeText'), '备份完成前必须回读校验目标文件。');
assert(backupSource.includes('encodeBase64(bytes)'), 'v2 备份必须内嵌原图。');
assert(backupSource.includes('sha256Bytes(bytes)'), '备份原图必须单独校验完整性。');
assert(backupSource.includes('expectedChecksum !== envelope.checksum'), '恢复前必须校验 checksum。');
assert(backupSource.includes('payload.reviewCount !== payload.reviews.length'), '恢复前必须校验记录数量。');
assert(backupSource.includes('usedIds.has(record.reviewId)'), '恢复前必须拒绝重复复盘 ID。');
assert(backupSource.includes('record.reviewId !== getReviewDocumentKey(record.document)'), '恢复前必须校验复盘主键一致性。');
assert(backupSource.includes('rawText.length > REVIEW_LIBRARY_BACKUP_MAX_TEXT_LENGTH'), '恢复必须限制备份文件大小。');
assert(!backupSource.includes('HomeStorageSecretService'), '备份不得包含家庭存储密码。');

const restoreBody = extractMethodBody(backupSource, 'static async restoreInspectedBackup');
assert(restoreBody.includes('ReviewCardHistoryService.replaceAllFromBackup'), '恢复必须走统一历史服务。');
assert(restoreBody.includes('fileUri.getUriFromPath(imagePath)'), '恢复必须把图片 URI 重写为应用内持久文件。');
assert(restoreBody.includes('cleanupRestoredImages'), '恢复后必须清理不再引用的旧图片。');
assert(restoreBody.includes('saveReviewerName'), '恢复应包含复盘人设置。');
assert(restoreBody.includes('saveWidgetCardBackgroundStyle'), '恢复应包含卡片背景设置。');
assert(restoreBody.includes('saveShatterAnimationEnabled'), '恢复应包含删除动画设置。');

const transactionBody = extractMethodBody(rdbSource, 'static async replaceAllReviews');
assert(transactionBody.includes('createTransaction()'), '整体恢复必须创建 RDB 事务。');
assert(transactionBody.includes('transaction.delete('), '整体恢复必须在事务内清理旧数据。');
assert(transactionBody.includes('transaction.insert('), '整体恢复必须在事务内写入备份数据。');
assert(transactionBody.includes('ON_CONFLICT_ABORT'), '恢复遇到冲突时必须中止。');
assert(transactionBody.includes('transaction.commit()'), '恢复成功必须提交事务。');
assert(transactionBody.includes('transaction.rollback()'), '恢复失败必须回滚事务。');

const historyRestoreBody = extractMethodBody(historySource, 'static async replaceAllFromBackup');
assert(historyRestoreBody.includes('markRdbMainIndexReady'), '恢复后必须保持 RDB 主索引状态。');
assert(historyRestoreBody.includes('clearRecoverableBackups'), '恢复后必须清理旧沙箱副本。');
assert(historyRestoreBody.includes('writeRecoverableBackup'), '恢复后必须重建逐条沙箱副本。');
assert(historyRestoreBody.includes("notifyReviewLibraryChanged('library_backup_restored')"), '恢复后必须刷新复盘库。');

assert(!myPageSource.includes("Text('数据保护')"), '我的页不得展示“数据保护”小标题。');
assert(myPageSource.includes("title: '备份全部复盘'"), '我的页必须提供完整备份入口。');
assert(myPageSource.includes("title: '从备份恢复'"), '我的页必须提供恢复入口。');
assert(myPageSource.includes('支持多选备份'), '我的页必须明确恢复支持多选。');
assert(myPageSource.includes('复盘与原图保存到手机文件'), '我的页必须明确备份包含原图。');
assert(appShellSource.includes('shouldOfferFirstLaunchRestore'), '空库首次启动必须提供恢复引导。');
assert(appShellSource.includes('DebugLaunchScenarioService.isAutomatedTestLaunch()'), '自动化启动必须跳过恢复引导。');
assert(debugLaunchSource.includes('automatedTestLaunch = scenario.length > 0'), '测试场景必须留下自动化启动标记。');

function checksum(payload) {
  return crypto.createHash('sha256').update(JSON.stringify(payload), 'utf8').digest('hex');
}

function inspectEnvelope(envelope) {
  if (envelope.schemaName !== 'JianYuReviewLibraryBackup' || !['v1', 'v2'].includes(envelope.schemaVersion)) {
    throw new Error('schema invalid');
  }
  if (checksum(envelope.payload) !== envelope.checksum) {
    throw new Error('checksum invalid');
  }
  if (envelope.payload.reviewCount !== envelope.payload.reviews.length) {
    throw new Error('count invalid');
  }
  const ids = new Set();
  for (const record of envelope.payload.reviews) {
    if (ids.has(record.reviewId)) {
      throw new Error('duplicate id');
    }
    ids.add(record.reviewId);
  }
  return envelope.payload.reviews.length;
}

const payload = {
  createdAt: 1,
  appVersion: '0.1.0',
  reviewCount: 2,
  reviews: [
    { reviewId: '100', document: { createdAt: 100 }, exportedPath: '' },
    { reviewId: '200', document: { createdAt: 200 }, exportedPath: '/photo/200.jpg' }
  ],
  settings: {
    reviewerName: '见遇',
    widgetCardBackgroundStyle: 'corner',
    shatterAnimationEnabled: true
  }
};
const validEnvelope = {
  schemaName: 'JianYuReviewLibraryBackup',
  schemaVersion: 'v1',
  checksumAlgorithm: 'SHA-256',
  checksum: checksum(payload),
  payload
};
assert(inspectEnvelope(validEnvelope) === 2, '有效备份应通过模型校验。');

const tamperedEnvelope = structuredClone(validEnvelope);
tamperedEnvelope.payload.reviews[0].reviewId = 'changed';
let tamperedRejected = false;
try {
  inspectEnvelope(tamperedEnvelope);
} catch (error) {
  tamperedRejected = true;
}
assert(tamperedRejected, '被篡改的备份必须被 checksum 拒绝。');

const duplicatePayload = structuredClone(payload);
duplicatePayload.reviews[1].reviewId = duplicatePayload.reviews[0].reviewId;
const duplicateEnvelope = {
  ...validEnvelope,
  payload: duplicatePayload,
  checksum: checksum(duplicatePayload)
};
let duplicateRejected = false;
try {
  inspectEnvelope(duplicateEnvelope);
} catch (error) {
  duplicateRejected = true;
}
assert(duplicateRejected, 'checksum 正确但 ID 重复的备份仍必须被拒绝。');

function mergeRecord(existing, candidate) {
  const contentWinner = candidate.document.updatedAt > existing.document.updatedAt ? candidate : existing;
  return {
    ...structuredClone(contentWinner),
    image: contentWinner.image || candidate.image || existing.image
  };
}

const embeddedBytes = Buffer.from('review-photo-binary');
const embeddedImage = {
  fileName: '100.jpg',
  byteLength: embeddedBytes.length,
  checksum: crypto.createHash('sha256').update(embeddedBytes).digest('hex'),
  dataBase64: embeddedBytes.toString('base64')
};
assert(Buffer.from(embeddedImage.dataBase64, 'base64').equals(embeddedBytes), '原图 Base64 必须可以无损往返。');

const mergedRecord = mergeRecord(
  { reviewId: '100', document: { createdAt: 100, updatedAt: 100, title: '旧内容' }, image: embeddedImage },
  { reviewId: '100', document: { createdAt: 100, updatedAt: 200, title: '新内容' } }
);
assert(mergedRecord.document.title === '新内容', '多备份合并必须保留更新时间更晚的内容。');
assert(mergedRecord.image?.checksum === embeddedImage.checksum, '较新记录缺图时必须保留旧备份中的可用原图。');

if (failed) {
  process.exit(1);
}
