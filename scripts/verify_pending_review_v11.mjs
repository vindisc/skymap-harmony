import fs from 'node:fs';

const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const projectDetailPageSource = fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8');
const editorPageSource = fs.readFileSync('entry/src/main/ets/pages/EditorPage.ets', 'utf8');
const statsPageSource = fs.readFileSync('entry/src/main/ets/pages/StatsPage.ets', 'utf8');
const storeSource = fs.readFileSync('entry/src/main/ets/services/PendingReviewPhotoStore.ets', 'utf8');
const modelSource = fs.readFileSync('entry/src/main/ets/model/PendingReviewPhotoModel.ets', 'utf8');
const reviewCardStoreSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardStore.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

function requireIncludes(source, marker, message) {
  assert(source.includes(marker), `${message}: ${marker}`);
}

[
  "label: this.isPickingPhoto ? REVIEW_FLOW_IMPORT_PENDING_TEXT : '导入照片，开始复盘'",
  'ReviewCardStore.createPhotoDraft(',
  'this.getUIContext().getRouter().pushUrl({ url: EDITOR_PAGE })'
].forEach((marker) => requireIncludes(homePageSource, marker, 'Immediate review flow must stay on the existing route'));

[
  'const HOME_PENDING_IMPORT_MAX_SELECT_NUMBER: number = 30;',
  'pickMultiplePhotoDetails(HOME_PENDING_IMPORT_MAX_SELECT_NUMBER)',
  "label: this.isImportingPendingPhoto ? '正在加入待复盘…' : '导入待复盘'",
  'PendingReviewPhotoStore.addPhotos(',
  'formatFeedbackImportSummary(0, failedCount)',
  'formatFeedbackImportSummary(successCount, failedCount)',
  'formatFeedbackPendingImportBatchSuccess(successCount)'
].forEach((marker) => requireIncludes(homePageSource, marker, 'Pending import must keep V1.1 batch behavior'));

assert(!homePageSource.includes('if (result.photos[index].imageSizeFallbackUsed)'),
  'Metadata fallback must not reject an otherwise selectable pending photo.');

assert(!homePageSource.includes('PendingReviewPhotoStore.addPhoto('),
  'HomePage should use PendingReviewPhotoStore.addPhotos for batch pending import.');

[
  'export interface PendingReviewPhoto',
  'photoUri: string;',
  'fileName: string;',
  'width: number;',
  'height: number;',
  'orientation: string;',
  'importTime: number;',
  'status: string;',
  'linkedReviewId: string;',
  "PENDING = 'pending'",
  "REVIEWED = 'reviewed'"
].forEach((marker) => requireIncludes(modelSource, marker, 'PendingReviewPhoto model must keep required fields'));

[
  'static async addPhotos',
  'static async listPending',
  'static async getOldestPending',
  'static async getById',
  'static async countPending',
  'static async getStats',
  'static async markReviewed',
  'static async updateLinkedReviewId',
  'static async delete',
  'COUNT(1) AS total_imported',
  'ORDER BY import_time ASC LIMIT 1',
  'SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) AS pending_total',
  'SUM(CASE WHEN status = ? THEN 1 ELSE 0 END) AS reviewed_total'
].forEach((marker) => requireIncludes(storeSource, marker, 'PendingReviewPhotoStore must cover V1.1 responsibilities'));

[
  "const PENDING_REVIEW_FILTER: string = 'pending';",
  "this.FilterChip('全部', 'all')",
  "this.FilterChip('待复盘', PENDING_REVIEW_FILTER)",
  "this.FilterChip('成立', ReviewJudgementStatus.VALID)",
  "this.FilterChip('待判断', ReviewJudgementStatus.UNSURE)",
  "this.FilterChip('不成立', ReviewJudgementStatus.INVALID)",
  'private isAllFilter(): boolean',
  'private isDeletingAnyItem(): boolean',
  'if (this.isAllFilter()) {',
  'this.filteredItems = this.isPendingFilter() ? [] : result.items;',
  'ReviewCardStore.createPendingPhotoDraft(',
  "Text('图片不可访问')",
  'PendingReviewPhotoStore.delete('
].forEach((marker) => requireIncludes(projectDetailPageSource, marker,
  'Review library must keep Pending data separate while aggregating it into the all view'));

const allListStart = projectDetailPageSource.indexOf('if (this.isAllFilter()) {');
const allPendingIndex = projectDetailPageSource.indexOf('ForEach(this.resolveVisiblePendingItems()', allListStart);
const allHistoryIndex = projectDetailPageSource.indexOf('ForEach(this.filteredItems', allListStart);
assert(allListStart >= 0 && allPendingIndex > allListStart && allHistoryIndex > allPendingIndex,
  'All filter must render pending cards before every loaded history status.');
assert(projectDetailPageSource.split('if (this.isDeletingAnyItem())').length - 1 >= 4,
  'Mixed all-view deletion must use one lock across pending and history actions.');

[
  'private static currentPendingPhotoId: string =',
  'static createPendingPhotoDraft(',
  'static getCurrentPendingPhotoId()',
  'static clearCurrentPendingPhotoId()'
].forEach((marker) => requireIncludes(reviewCardStoreSource, marker, 'ReviewCardStore must carry pendingPhotoId without changing Review data shape'));

[
  '@State pendingPhotoId: string =',
  'this.pendingPhotoId = ReviewCardStore.getCurrentPendingPhotoId();',
  'await ReviewCardHistoryService.saveDocument(this.getAbilityContext(), this.document);',
  'await this.markPendingPhotoReviewedQuietly();',
  'PendingReviewPhotoStore.markReviewed(',
  'getReviewDocumentKey(this.document)',
  '正式复盘已保存，但待复盘状态更新失败'
].forEach((marker) => requireIncludes(editorPageSource, marker, 'Editor must save Review first and quietly mark Pending reviewed'));

[
  'LearningProgressService.loadWithReviewItems(context)',
  'ReviewProjectService.buildStatsFeedback(progressResult.reviewItems)',
  'resolveLearningTotalImportedCount()',
  'return this.learningStats.totalImportedCount;',
  'return this.learningStats.completedCount;',
  "Text('学习进度')",
  "this.LearningMetric('累计导入'",
  "this.LearningMetric('待复盘'",
  "this.LearningMetric('已完成'",
  "this.LearningMetric('完成率'",
  "Text('复盘结果')",
  "Text('累计复盘')",
  "Text('最近 30 天')",
  "Text('判断分布')"
].forEach((marker) => requireIncludes(statsPageSource, marker, 'Stats page must keep learning progress and review results separate'));

assert(!statsPageSource.includes('PendingReviewPhotoStore.getStats(context).then'),
  'Stats loading should await Pending stats independently before building Review stats.');
assert(!statsPageSource.includes("Text('最近复盘')"),
  'Stats page should not render the removed recent reviews module.');
assert(!statsPageSource.includes('RecentReviewsCard()'),
  'Stats page should remove the recent reviews card builder.');

if (failed) {
  process.exit(1);
}

console.log('pending review v1.1 verified: batch import, library tab, editor linkage, and split stats');
