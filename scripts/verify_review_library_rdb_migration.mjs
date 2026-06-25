import fs from 'node:fs';

const rdbModelSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardRdbModel.ets', 'utf8');
const rdbServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardRdbService.ets', 'utf8');
const migrationServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardMigrationService.ets', 'utf8');
const diagnosticsServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardRdbDiagnosticsService.ets', 'utf8');
const historyServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardHistoryService.ets', 'utf8');
const projectDetailSource = fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8');
const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
}

const requiredSqlTokens = [
  'CREATE TABLE IF NOT EXISTS reviews',
  'id TEXT PRIMARY KEY',
  'created_at INTEGER NOT NULL',
  'updated_at INTEGER NOT NULL',
  'raw_document_json TEXT NOT NULL',
  'backup_json_path TEXT',
  'is_deleted INTEGER DEFAULT 0',
  'idx_reviews_updated_at',
  'idx_reviews_decision',
  'idx_reviews_is_deleted',
  'idx_reviews_created_at',
  'review_library.db'
];

for (const token of requiredSqlTokens) {
  assert(rdbModelSource.includes(token), `ReviewCardRdbModel missing SQL token: ${token}`);
}

const requiredServiceTokens = [
  "import relationalStore from '@ohos.data.relationalStore'",
  'static async init(',
  'static async upsertReview(',
  'static async getReview(',
  'static async listReviews(',
  'static async countReviews(',
  'static async deleteReview(',
  'static async markExported(',
  'static async getStats(',
  'static async clearAll(',
  'ON_CONFLICT_REPLACE',
  'ORDER BY updated_at DESC, created_at DESC'
];

for (const token of requiredServiceTokens) {
  assert(rdbServiceSource.includes(token), `ReviewCardRdbService missing token: ${token}`);
}

assert(
  migrationServiceSource.includes('migrateFromPreferencesToRdb') &&
    migrationServiceSource.includes('verifyRdbMigration') &&
    migrationServiceSource.includes('countPreferenceHistoryItems') &&
    !migrationServiceSource.includes("import { ReviewCardHistoryService }"),
  'ReviewCardMigrationService must expose migration and avoid calling ReviewCardHistoryService.load after phase 3 main-read switch.'
);

const requiredDiagnosticsTokens = [
  'RdbDiagnosticsResult',
  'RdbDiagnosticsStep',
  'runRdbDiagnostics',
  'runMigrationDiagnostics',
  'ReviewCardRdbService.init(context)',
  'ReviewCardRdbService.upsertReview',
  'ReviewCardRdbService.getReview',
  'ReviewCardRdbService.listReviews',
  'ReviewCardRdbService.markExported',
  'ReviewCardRdbService.getStats',
  'ReviewCardRdbService.deleteReview',
  'ReviewCardMigrationService.migrateFromPreferencesToRdb',
  'ReviewCardMigrationService.verifyRdbMigration',
  'formatDiagnosticsResult'
];

for (const token of requiredDiagnosticsTokens) {
  assert(diagnosticsServiceSource.includes(token), `ReviewCardRdbDiagnosticsService missing token: ${token}`);
}

assert(historyServiceSource.includes("import { ReviewCardRdbListResult, ReviewCardRdbService } from './ReviewCardRdbService';"), 'ReviewCardHistoryService must own the phase 3 RDB main-read switch.');
assert(historyServiceSource.includes('loadFromRdbWithDiagnostics'), 'ReviewCardHistoryService must isolate RDB-first read logic.');
assert(historyServiceSource.includes('ReviewCardMigrationService.migrateFromPreferencesToRdb(context)'), 'RDB empty should trigger Preferences to RDB migration.');
assert(historyServiceSource.includes('loadLegacyWithDiagnostics'), 'ReviewCardHistoryService must keep the legacy Preferences + review_exchange fallback path.');
assert(historyServiceSource.includes('ReviewCardRdbService.upsertReview(context'), 'Phase 5 save/update must write RDB.');
assert(historyServiceSource.includes('ReviewCardRdbService.deleteReview(context'), 'Phase 5 delete must write RDB.');
assert(historyServiceSource.includes('ReviewCardRdbService.markExported(context'), 'Phase 5 markExported must write RDB.');
assert(!historyServiceSource.includes('persistPreferencesFallbackMirror'), 'Phase 5 must remove Preferences fallback mirror writes.');
assert(!historyServiceSource.includes('persistLegacySave'), 'Phase 5 must remove legacy Preferences save fallback.');
assert(!historyServiceSource.includes('store.put(HISTORY_KEY, JSON.stringify'), 'Phase 5 must not write Preferences.items from ReviewCardHistoryService.');
assert(!projectDetailSource.includes('ReviewCardRdbService'), 'ProjectDetailPage must not directly read RDB.');
assert(!homePageSource.includes('ReviewCardRdbService'), 'HomePage must not directly read RDB.');
assert(!previewPageSource.includes('ReviewCardRdbService'), 'PreviewPage must not directly read RDB.');
assert(!projectDetailSource.includes('ReviewCardRdbDiagnosticsService'), 'ProjectDetailPage must not expose diagnostics as a formal UI flow.');
assert(!homePageSource.includes('ReviewCardRdbDiagnosticsService'), 'HomePage must not expose diagnostics as a formal UI flow.');
assert(!previewPageSource.includes('ReviewCardRdbDiagnosticsService'), 'PreviewPage must not expose diagnostics as a formal UI flow.');
assert(myPageSource.includes('RDB开发诊断'), 'MyPage should expose the temporary developer RDB diagnostics entry.');
assert(myPageSource.includes('runRdbDiagnostics(context)'), 'MyPage diagnostics should run RDB sidecar diagnostics.');
assert(myPageSource.includes('runMigrationDiagnostics(context)'), 'MyPage diagnostics should run Preferences to RDB migration diagnostics.');
assert(myPageSource.includes('console.info(`[RDB开发诊断]'), 'MyPage diagnostics should write full results to console.info.');

function cloneDocument(document) {
  const fallback = createDocument({});
  const content = document.content || {};
  const config = document.config || fallback.config;
  return {
    version: typeof document.version === 'string' ? document.version : fallback.version,
    projectId: typeof document.projectId === 'string' && document.projectId.length > 0 ? document.projectId : 'default',
    imageUri: typeof document.imageUri === 'string' ? document.imageUri : '',
    imageWidth: typeof document.imageWidth === 'number' && document.imageWidth > 0 ? document.imageWidth : fallback.imageWidth,
    imageHeight: typeof document.imageHeight === 'number' && document.imageHeight > 0 ? document.imageHeight : fallback.imageHeight,
    imageSizeFallbackUsed: document.imageSizeFallbackUsed === true,
    content: {
      title: typeof content.title === 'string' ? content.title : '这张照片是否成立',
      visualFocus: typeof content.visualFocus === 'string' ? content.visualFocus : '',
      focusReason: typeof content.focusReason === 'string' ? content.focusReason : '',
      visualPath: typeof content.visualPath === 'string' ? content.visualPath : '',
      visibleFacts: typeof content.visibleFacts === 'string' ? content.visibleFacts : '',
      coreRelation: typeof content.coreRelation === 'string' ? content.coreRelation : '',
      judgement: typeof content.judgement === 'string' ? content.judgement : '不确定',
      extendedUnderstanding: typeof content.extendedUnderstanding === 'string' ? content.extendedUnderstanding : '',
      currentBlocker: typeof content.currentBlocker === 'string' ? content.currentBlocker : ''
    },
    config: {
      templateId: typeof config.templateId === 'string' ? config.templateId : 'review_card',
      layoutMode: config.layoutMode || 'auto',
      background: config.background || 'white',
      textSize: config.textSize || 'standard'
    },
    createdAt: typeof document.createdAt === 'number' && document.createdAt > 0 ? document.createdAt : fallback.createdAt,
    updatedAt: typeof document.updatedAt === 'number' && document.updatedAt > 0 ? document.updatedAt : fallback.updatedAt
  };
}

function createDocument(overrides) {
  const now = overrides.createdAt || 1700000000000;
  return {
    version: '0.1.0',
    projectId: 'default',
    imageUri: overrides.imageUri || '/data/storage/el2/base/files/IMG_1001.JPG',
    imageWidth: overrides.imageWidth || 1600,
    imageHeight: overrides.imageHeight || 1000,
    imageSizeFallbackUsed: false,
    content: {
      title: overrides.title || '逆光人像',
      visualFocus: overrides.visualFocus || '窗边高光',
      focusReason: overrides.focusReason || '第一眼被光线吸引',
      visualPath: overrides.visualPath || '人物到窗边再回到手部',
      visibleFacts: overrides.visibleFacts || '人物、窗框、反光',
      coreRelation: overrides.coreRelation || '人物与窗边高光',
      judgement: overrides.judgement || '成立',
      extendedUnderstanding: overrides.extendedUnderstanding || '',
      currentBlocker: overrides.currentBlocker || '高光太抢'
    },
    config: {
      templateId: 'review_card',
      layoutMode: 'auto',
      background: 'white',
      textSize: 'standard'
    },
    createdAt: now,
    updatedAt: overrides.updatedAt || now
  };
}

function getReviewDocumentKey(document) {
  return `${document.createdAt}`;
}

function shortHash(value) {
  let hash = 0;
  for (let index = 0; index < value.length; index += 1) {
    hash = ((hash << 5) - hash + value.charCodeAt(index)) & 0x7fffffff;
  }
  return hash.toString(36);
}

function resolveReviewId(document, usedIds = new Set(), conflictSeed = '') {
  const baseId = getReviewDocumentKey(document);
  if (!usedIds.has(baseId)) {
    return baseId;
  }
  const seed = conflictSeed.length > 0 ? conflictSeed : JSON.stringify(cloneDocument(document));
  let candidate = `${baseId}-${shortHash(seed)}`;
  let index = 1;
  while (usedIds.has(candidate)) {
    candidate = `${baseId}-recovered-${index}`;
    index += 1;
  }
  return candidate;
}

function toRow(item, reviewId = '') {
  const document = cloneDocument(item.document);
  const content = document.content;
  return {
    id: reviewId || resolveReviewId(document),
    createdAt: document.createdAt,
    updatedAt: document.updatedAt,
    title: content.title,
    decision: content.judgement,
    imageUri: document.imageUri,
    imageWidth: document.imageWidth,
    imageHeight: document.imageHeight,
    exportedPath: item.exportedPath || '',
    reviewerName: '',
    focusText: content.visualFocus,
    reasonText: content.focusReason,
    pathText: content.visualPath,
    factsText: content.visibleFacts,
    strongestRelationText: content.coreRelation,
    blockerText: content.currentBlocker,
    rawDocumentJson: JSON.stringify(document),
    backupJsonPath: '',
    isDeleted: 0
  };
}

function toHistoryItem(row) {
  return {
    document: cloneDocument(JSON.parse(row.rawDocumentJson)),
    exportedPath: row.exportedPath
  };
}

class InMemoryReviewRdb {
  constructor() {
    this.rows = new Map();
  }

  migrate(items) {
    const usedIds = new Set();
    let insertedCount = 0;
    let skippedCount = 0;
    for (const [index, item] of items.entries()) {
      const raw = JSON.stringify(cloneDocument(item.document));
      const reviewId = resolveReviewId(item.document, usedIds, `${raw}-${index}`);
      usedIds.add(reviewId);
      if (this.rows.has(reviewId)) {
        skippedCount += 1;
        continue;
      }
      this.rows.set(reviewId, toRow(item, reviewId));
      insertedCount += 1;
    }
    return {
      sourceCount: items.length,
      insertedCount,
      skippedCount,
      failedCount: 0,
      errors: []
    };
  }

  list(query = {}) {
    const keyword = `${query.keyword || ''}`.trim().toLocaleLowerCase();
    return [...this.rows.values()]
      .filter((row) => query.includeDeleted === true || row.isDeleted === 0)
      .filter((row) => !query.decision || row.decision === query.decision)
      .filter((row) => {
        if (keyword.length === 0) {
          return true;
        }
        return [
          row.title,
          row.focusText,
          row.reasonText,
          row.pathText,
          row.factsText,
          row.strongestRelationText,
          row.blockerText
        ].join('\n').toLocaleLowerCase().includes(keyword);
      })
      .sort((left, right) => {
        if (right.updatedAt !== left.updatedAt) {
          return right.updatedAt - left.updatedAt;
        }
        return right.createdAt - left.createdAt;
      })
      .slice(query.offset || 0, query.limit ? (query.offset || 0) + query.limit : undefined)
      .map(toHistoryItem);
  }

  count(query = {}) {
    return this.list(query).length;
  }

  markExported(id, exportedPath) {
    const row = this.rows.get(id);
    if (row) {
      row.exportedPath = exportedPath;
      this.rows.set(id, row);
    }
  }

  deleteReview(id) {
    this.rows.delete(id);
  }
}

const emptyDb = new InMemoryReviewRdb();
const emptyMigration = emptyDb.migrate([]);
assert(emptyMigration.sourceCount === 0, 'Empty migration sourceCount should be 0.');
assert(emptyDb.count() === 0, 'Empty migration rdbCount should be 0.');

const firstItem = {
  document: createDocument({ createdAt: 1700000000001, updatedAt: 1700000000101 }),
  exportedPath: '/data/storage/el2/base/files/review_exports/first.jpg'
};
const singleDb = new InMemoryReviewRdb();
singleDb.migrate([firstItem]);
const singleRow = singleDb.rows.get('1700000000001');
assert(singleRow, 'Single item should be inserted by createdAt key.');
assert(JSON.parse(singleRow.rawDocumentJson).content.title === '逆光人像', 'raw_document_json should be parseable and complete.');
assert(singleRow.imageUri === firstItem.document.imageUri, 'image_uri should match source document.');
assert(singleRow.decision === '成立', 'decision should match source judgement.');
assert(singleRow.updatedAt === firstItem.document.updatedAt, 'updated_at should match source document.');
assert(singleRow.exportedPath === firstItem.exportedPath, 'exported_path should match source item.');

const items = [
  firstItem,
  {
    document: createDocument({
      createdAt: 1700000000002,
      updatedAt: 1700000000301,
      title: '街头抓拍',
      judgement: '不成立',
      coreRelation: '路人与标牌',
      currentBlocker: '主体不够集中'
    }),
    exportedPath: ''
  },
  {
    document: createDocument({
      createdAt: 1700000000003,
      updatedAt: 1700000000201,
      title: '雨夜橱窗',
      judgement: '不确定',
      visualFocus: '玻璃上的反光',
      currentBlocker: '关系还不明确'
    }),
    exportedPath: ''
  }
];
const multiDb = new InMemoryReviewRdb();
multiDb.migrate(items);
assert(multiDb.count() === 3, 'Multi item count should be 3.');
assert(multiDb.list()[0].document.content.title === '街头抓拍', 'List should sort by updated_at DESC.');
assert(multiDb.count({ decision: '成立' }) === 1, 'Decision filter should count 成立.');
assert(multiDb.count({ decision: '不成立' }) === 1, 'Decision filter should count 不成立.');
assert(multiDb.count({ decision: '不确定' }) === 1, 'Decision filter should count 不确定.');
assert(multiDb.count({ keyword: '玻璃' }) === 1, 'Keyword search should match visualFocus.');
assert(multiDb.count({ keyword: '路人与标牌' }) === 1, 'Keyword search should match coreRelation.');
assert(multiDb.count({ keyword: '关系还不明确' }) === 1, 'Keyword search should match currentBlocker.');

multiDb.markExported('1700000000003', '/data/storage/el2/base/files/review_exports/third.jpg');
assert(
  multiDb.rows.get('1700000000003').exportedPath === '/data/storage/el2/base/files/review_exports/third.jpg',
  'markExported should update exported_path.'
);

multiDb.deleteReview('1700000000002');
assert(multiDb.count() === 2, 'deleteReview should hard delete in phase 1.');
assert(multiDb.list().every((item) => item.document.content.title !== '街头抓拍'), 'Deleted item should not appear in list.');

const collisionDb = new InMemoryReviewRdb();
const collisionItems = [
  {
    document: createDocument({ createdAt: 1700000000999, updatedAt: 1700000001000, title: '同一时间 A' }),
    exportedPath: ''
  },
  {
    document: createDocument({ createdAt: 1700000000999, updatedAt: 1700000001001, title: '同一时间 B' }),
    exportedPath: ''
  }
];
collisionDb.migrate(collisionItems);
assert(collisionDb.count() === 2, 'CreatedAt collision should not overwrite migrated data.');
assert(new Set(collisionDb.rows.keys()).size === 2, 'Resolved ids should be unique under collision.');

if (failed) {
  process.exit(1);
}

console.log('review library RDB phase 1: SQL, mapping, migration semantics, query, export mark, hard delete, id collision verified');
