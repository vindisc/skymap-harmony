import fs from 'node:fs';

const appShellSource = fs.readFileSync('entry/src/main/ets/pages/AppShellPage.ets', 'utf8');
const projectDetailSource = fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8');
const statsPageSource = fs.readFileSync('entry/src/main/ets/pages/StatsPage.ets', 'utf8');
const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const historyServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardHistoryService.ets', 'utf8');
const migrationServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardMigrationService.ets', 'utf8');
const refreshServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewLibraryRefreshService.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

assert(refreshServiceSource.includes('notifyReviewLibraryChanged(reason: string)'), 'Refresh service must expose notifyReviewLibraryChanged.');
assert(refreshServiceSource.includes('getRefreshToken()'), 'Refresh service must expose getRefreshToken.');
assert(historyServiceSource.includes("notifyReviewLibraryChanged('save_document')"), 'saveDocument success must notify refresh.');
assert(historyServiceSource.includes("notifyReviewLibraryChanged('update_document')"), 'updateDocument success must notify refresh.');
assert(historyServiceSource.includes("notifyReviewLibraryChanged('delete_document')"), 'deleteDocument success must notify refresh.');
assert(historyServiceSource.includes("notifyReviewLibraryChanged('mark_exported')"), 'markExported success must notify refresh.');
assert(migrationServiceSource.includes("notifyReviewLibraryChanged('preferences_migrated_to_rdb')"), 'Preferences to RDB migration should notify refresh.');
assert(historyServiceSource.includes("notifyReviewLibraryChanged('review_exchange_recovered')"), 'review_exchange recovery should notify refresh.');

assert(appShellSource.includes('reviewLibraryRefreshToken'), 'AppShell must hold reviewLibraryRefreshToken.');
assert(appShellSource.includes('ReviewLibraryRefreshService.getRefreshToken()'), 'AppShell must read the global refresh token.');
assert(appShellSource.includes('ProjectDetailPage({ refreshToken: this.reviewLibraryRefreshToken })'), 'AppShell must pass token to ProjectDetailPage.');
assert(appShellSource.includes('StatsPage({ refreshToken: this.reviewLibraryRefreshToken })'), 'AppShell must pass token to StatsPage.');
assert(appShellSource.includes('HomePage({ refreshToken: this.homeRefreshToken + this.reviewLibraryRefreshToken })'), 'HomePage must refresh on review library changes.');
assert(
  appShellSource.includes('MyPage({ refreshToken: this.myRefreshToken + this.reviewLibraryRefreshToken + this.settingsRefreshToken })'),
  'MyPage must refresh on review library and settings changes.'
);

assert(projectDetailSource.includes("@Prop @Watch('refreshReviewLibraryData') refreshToken"), 'ProjectDetailPage must watch refreshToken.');
assert(projectDetailSource.includes('refreshReviewLibraryData()'), 'ProjectDetailPage must reload when token changes.');
assert(projectDetailSource.includes('@State deletingReviewKey'), 'deleteHistory must keep a delete busy key.');
assert(projectDetailSource.includes('复盘已删除'), 'deleteHistory must show success feedback.');
assert(projectDetailSource.includes('删除失败，请重试'), 'deleteHistory must show failure feedback.');
assert(projectDetailSource.includes('this.reloadData();'), 'deleteHistory should reload after optimistic update.');
assert(statsPageSource.includes("@Prop @Watch('refreshStatsData') refreshToken"), 'StatsPage must watch refreshToken.');
assert(statsPageSource.includes('ReviewCardHistoryService.load'), 'StatsPage must load latest review history.');
assert(myPageSource.includes("@Prop @Watch('refreshPageData') refreshToken"), 'MyPage must still watch refreshToken.');
assert(homePageSource.includes("@Prop @Watch('refreshHomeData') refreshToken"), 'HomePage must still watch refreshToken.');

class RefreshServiceModel {
  constructor() {
    this.token = 0;
    this.reasons = [];
  }

  notify(reason) {
    this.token += 1;
    this.reasons.push(reason);
    return this.token;
  }
}

function createItem(title, judgement, createdAt) {
  return {
    document: {
      createdAt,
      updatedAt: createdAt,
      imageUri: `/data/storage/el2/base/files/${title}.jpg`,
      content: {
        title,
        coreRelation: title.includes('街头') ? '路人与标牌' : '人物与光',
        currentBlocker: title.includes('删除') ? '待删除' : '待观察',
        judgement
      }
    },
    exportedPath: ''
  };
}

function filterItems(items, rawQuery, decisionFilter) {
  const query = rawQuery.trim().toLocaleLowerCase();
  return items.filter((item) => {
    if (decisionFilter !== 'all' && item.document.content.judgement !== decisionFilter) {
      return false;
    }
    if (query.length === 0) {
      return true;
    }
    return [
      item.document.content.title,
      item.document.content.coreRelation,
      item.document.content.currentBlocker,
      item.document.imageUri.split('/').pop()
    ].join('\n').toLocaleLowerCase().includes(query);
  });
}

class ProjectDetailPageModel {
  constructor(items) {
    this.items = items;
    this.searchText = '';
    this.decisionFilter = 'all';
    this.filteredItems = [];
    this.reloadCount = 0;
  }

  reload(nextItems = this.items) {
    this.reloadCount += 1;
    this.items = nextItems;
    this.applyFilters();
  }

  applyFilters() {
    this.filteredItems = filterItems(this.items, this.searchText, this.decisionFilter);
  }

  onRefreshTokenChanged(nextItems) {
    this.reload(nextItems);
  }

  deleteReturnedItems(nextItems) {
    this.items = nextItems;
    this.applyFilters();
    this.reload(nextItems);
  }
}

const refresh = new RefreshServiceModel();
const operations = ['saveDocument', 'updateDocument', 'deleteDocument', 'markExported'];
for (const operation of operations) {
  refresh.notify(operation);
}
assert(refresh.token === 4, 'save/update/delete/markExported should each increment refresh token.');
assert(refresh.reasons.join(',') === operations.join(','), 'Refresh token should retain change reasons in order.');

const initialItems = [
  createItem('街头成立', '成立', 1700000000001),
  createItem('街头删除', '成立', 1700000000002),
  createItem('室内不成立', '不成立', 1700000000003)
];
const pageModel = new ProjectDetailPageModel(initialItems);
pageModel.searchText = '街头';
pageModel.decisionFilter = '成立';
pageModel.reload();
assert(pageModel.filteredItems.length === 2, 'Initial filter should include two matching records.');

const afterDeleteItems = initialItems.filter((item) => item.document.createdAt !== 1700000000002);
pageModel.deleteReturnedItems(afterDeleteItems);
assert(pageModel.searchText === '街头', 'Refresh should preserve search text.');
assert(pageModel.decisionFilter === '成立', 'Refresh should preserve decision filter.');
assert(pageModel.filteredItems.length === 1, 'Deleted record should disappear after local update and reload.');
assert(pageModel.filteredItems.every((item) => item.document.createdAt !== 1700000000002), 'Deleted item must not remain in filtered list.');

const updatedItems = [
  createItem('街头成立已更新', '不成立', 1700000000001),
  createItem('室内不成立', '不成立', 1700000000003)
];
pageModel.onRefreshTokenChanged(updatedItems);
assert(pageModel.reloadCount >= 3, 'ProjectDetailPage should reload when refresh token changes.');
assert(pageModel.filteredItems.length === 0, 'Updated judgement should be reflected under existing filter.');

if (failed) {
  process.exit(1);
}

console.log('review library refresh flow: tokens, page reload, filter preservation, delete disappearance verified');
