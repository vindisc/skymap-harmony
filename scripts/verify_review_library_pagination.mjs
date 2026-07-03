import fs from 'node:fs';

const pageSource = fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8');
const historyServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardHistoryService.ets', 'utf8');
const rdbServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardRdbService.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

assert(pageSource.includes('const REVIEW_LIBRARY_PAGE_SIZE: number = 5'), 'Review library page size must stay at 5.');
assert(pageSource.includes('ReviewCardHistoryService.loadPage'), 'ProjectDetailPage must use paged history loading.');
assert(pageSource.includes('offset: 0'), 'Initial load must request the first page.');
assert(pageSource.includes('offset: this.filteredItems.length'), 'Load-more must continue from the loaded item count.');
assert(pageSource.includes('.onReachEnd(() =>'), 'List must load more when reaching the end.');
assert(pageSource.includes('this.loadMoreItems();'), 'Reach-end handler must call loadMoreItems.');
assert(pageSource.includes('this.filteredItems.length < result.totalCount'), 'Page must track whether more records are available.');
assert(pageSource.includes("summary.recordCount === 0 && !this.hasActiveFilters()"), 'Filtered empty state must not be treated as an empty library.');
assert(pageSource.includes('libraryStats: ReviewLibraryStats'), 'ProjectDetailPage must keep whole-library judgement stats.');
assert(pageSource.includes('return `已判断 ${this.libraryStats.works + this.libraryStats.notWorks}/${this.libraryStats.total}`;'), 'Header badge must show decided count over total count.');
assert(!pageSource.includes('return `${this.filteredItems.length}/${this.summary.recordCount}`;'), 'Header badge must not show loaded-or-filtered item count over total count.');

assert(historyServiceSource.includes('export interface ReviewCardHistoryPageResult'), 'History service must expose a page result.');
assert(historyServiceSource.includes('libraryStats: ReviewLibraryStats;'), 'Paged result must include whole-library stats.');
assert(historyServiceSource.includes('export interface ReviewCardHistoryPageQuery'), 'History service must expose a page query.');
assert(historyServiceSource.includes('static async loadPage('), 'History service must expose loadPage.');
assert(historyServiceSource.includes('ReviewCardRdbService.countReviews(context'), 'Paged load must return a total count.');
assert(historyServiceSource.includes('ReviewCardRdbService.getStats(context)'), 'Paged load must fetch whole-library judgement stats.');
assert(historyServiceSource.includes('buildLegacyLibraryStats(result.items)'), 'Legacy page fallback must also return whole-library judgement stats.');
assert(historyServiceSource.includes('ReviewCardRdbService.listReviewsWithDiagnostics(context, rdbQuery)'), 'Paged load must query RDB with limit and offset.');
assert(historyServiceSource.includes('loadPageFromLegacy'), 'Paged load must keep legacy fallback.');

assert(rdbServiceSource.includes('image_uri LIKE ?'), 'RDB search must include image_uri for file-name matching.');
assert(rdbServiceSource.includes('for (let index = 0; index < 8; index += 1)'), 'RDB search placeholder count must match searchable columns.');

if (failed) {
  process.exit(1);
}

console.log('review library pagination: first-page size, reach-end loading, RDB paging, fallback, and file-name search verified');
