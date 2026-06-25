import fs from 'node:fs';

const historyServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardHistoryService.ets', 'utf8');
const migrationServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardMigrationService.ets', 'utf8');
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

assert(
  historyServiceSource.includes("import { ReviewCardRdbListResult, ReviewCardRdbService } from './ReviewCardRdbService';"),
  'ReviewCardHistoryService must import ReviewCardRdbService for the phase 3 main-read switch.'
);
assert(
  historyServiceSource.includes('ReviewCardRdbService.init(context)') &&
    historyServiceSource.includes('ReviewCardRdbService.listReviewsWithDiagnostics(context'),
  'ReviewCardHistoryService.load must initialize and query RDB before legacy fallback.'
);
assert(
  historyServiceSource.includes('ReviewCardMigrationService.countPreferenceHistoryItems(context)') &&
    historyServiceSource.includes('ReviewCardMigrationService.migrateFromPreferencesToRdb(context)'),
  'RDB empty path must inspect Preferences source count and trigger Preferences to RDB migration.'
);
assert(
  historyServiceSource.includes('console.warn(`[ReviewCardHistoryService] RDB 主读失败，回退旧链路：'),
  'RDB failures must emit a diagnostic log before fallback.'
);
assert(
  historyServiceSource.includes('loadLegacyItemsForWrite') &&
    countOccurrences(historyServiceSource, 'ReviewCardHistoryService.loadLegacyItemsForWrite(context)') === 4,
  'save/update/delete/markExported must keep using the legacy Preferences-backed write base.'
);
assert(
  !migrationServiceSource.includes("import { ReviewCardHistoryService }") &&
    !migrationServiceSource.includes('ReviewCardHistoryService.load(context)'),
  'MigrationService must not call ReviewCardHistoryService.load after load becomes RDB-first.'
);
assert(!projectDetailSource.includes('ReviewCardRdbService'), 'ProjectDetailPage must not directly call RDB.');
assert(!homePageSource.includes('ReviewCardRdbService'), 'HomePage must not directly call RDB.');
assert(!previewPageSource.includes('ReviewCardRdbService'), 'PreviewPage must not directly call RDB.');
assert(!myPageSource.includes('ReviewCardRdbService'), 'MyPage must not directly call RDB outside diagnostics service.');

const writeMethodNames = ['saveDocument', 'updateDocument', 'markExported', 'deleteDocument'];
for (const methodName of writeMethodNames) {
  const body = extractMethodBody(historyServiceSource, `static async ${methodName}`);
  assert(body.includes('loadLegacyItemsForWrite(context)'), `${methodName} must read the legacy list as write base.`);
  assert(!body.includes('ReviewCardRdbService.'), `${methodName} must not switch to RDB main write in phase 3.`);
  assert(body.includes('persist(context') || methodName === 'updateDocument', `${methodName} must keep Preferences persistence.`);
}

function countOccurrences(source, token) {
  return source.split(token).length - 1;
}

function extractMethodBody(source, signature) {
  const start = source.indexOf(signature);
  assert(start >= 0, `Missing method signature: ${signature}`);
  if (start < 0) {
    return '';
  }
  const braceStart = source.indexOf('{', start);
  let depth = 0;
  for (let index = braceStart; index < source.length; index += 1) {
    const char = source[index];
    if (char === '{') {
      depth += 1;
    } else if (char === '}') {
      depth -= 1;
      if (depth === 0) {
        return source.slice(braceStart, index + 1);
      }
    }
  }
  return source.slice(braceStart);
}

function cloneDocument(document) {
  return JSON.parse(JSON.stringify(document));
}

function createItem(title, createdAt, updatedAt = createdAt, exportedPath = '') {
  return {
    document: {
      version: '0.1.0',
      projectId: 'default',
      imageUri: `/data/storage/el2/base/files/${title}.jpg`,
      imageWidth: 1600,
      imageHeight: 1000,
      imageSizeFallbackUsed: false,
      content: {
        title,
        visualFocus: '主体',
        focusReason: '第一眼被主体吸引',
        visualPath: '主体到背景',
        visibleFacts: '主体、背景',
        coreRelation: '主体与背景',
        judgement: '成立',
        extendedUnderstanding: '',
        currentBlocker: ''
      },
      config: {
        templateId: 'review_card',
        layoutMode: 'auto',
        background: 'white',
        textSize: 'standard'
      },
      createdAt,
      updatedAt
    },
    exportedPath
  };
}

function sortItems(items) {
  return [...items].sort((left, right) => {
    if (right.document.updatedAt !== left.document.updatedAt) {
      return right.document.updatedAt - left.document.updatedAt;
    }
    return right.document.createdAt - left.document.createdAt;
  });
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

class InMemoryRdb {
  constructor(options = {}) {
    this.rows = new Map();
    this.failInit = options.failInit === true;
    this.failQuery = options.failQuery === true;
    this.failMigration = options.failMigration === true;
    this.initCount = 0;
    this.queryCount = 0;
    this.migrationCount = 0;
  }

  init() {
    this.initCount += 1;
    if (this.failInit) {
      throw new Error('模拟 RDB init 失败');
    }
  }

  listWithDiagnostics() {
    this.queryCount += 1;
    if (this.failQuery) {
      throw new Error('模拟 RDB query 失败');
    }
    const rows = [...this.rows.values()].filter((row) => row.isDeleted !== 1);
    let invalidRowCount = 0;
    const items = [];
    for (const row of rows) {
      try {
        items.push({
          document: cloneDocument(JSON.parse(row.rawDocumentJson)),
          exportedPath: row.exportedPath || ''
        });
      } catch (error) {
        invalidRowCount += 1;
      }
    }
    return {
      items: sortItems(items),
      rowCount: rows.length,
      invalidRowCount
    };
  }

  migrate(preferenceItems) {
    this.migrationCount += 1;
    if (this.failMigration) {
      throw new Error('模拟迁移失败');
    }
    const usedIds = new Set();
    let insertedCount = 0;
    let skippedCount = 0;
    for (const [index, item] of preferenceItems.entries()) {
      const document = cloneDocument(item.document);
      const rawDocumentJson = JSON.stringify(document);
      const reviewId = resolveReviewId(document, usedIds, `${rawDocumentJson}-${index}`);
      usedIds.add(reviewId);
      if (this.rows.has(reviewId)) {
        skippedCount += 1;
        continue;
      }
      this.rows.set(reviewId, {
        id: reviewId,
        updatedAt: document.updatedAt,
        createdAt: document.createdAt,
        exportedPath: item.exportedPath || '',
        rawDocumentJson,
        isDeleted: 0
      });
      insertedCount += 1;
    }
    return {
      sourceCount: preferenceItems.length,
      insertedCount,
      skippedCount,
      failedCount: 0,
      errors: []
    };
  }
}

function legacyLoad(preferenceItems, backupItems = []) {
  const merged = [];
  const seen = new Set();
  for (const item of [...preferenceItems, ...backupItems]) {
    const key = getReviewDocumentKey(item.document);
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    merged.push({
      document: cloneDocument(item.document),
      exportedPath: item.exportedPath || ''
    });
  }
  return sortItems(merged);
}

function loadMainRead({ rdb, preferenceItems = [], backupItems = [] }) {
  const diagnostics = {
    rdbPrimaryReadAttempted: false,
    rdbPrimaryReadUsed: false,
    rdbMigrationAttempted: false,
    rdbFallbackUsed: false,
    rdbErrorMessage: '',
    rdbRowCount: 0,
    rdbParsedCount: 0,
    rdbInvalidRowCount: 0
  };

  try {
    diagnostics.rdbPrimaryReadAttempted = true;
    rdb.init();
    let rdbResult = rdb.listWithDiagnostics();
    diagnostics.rdbRowCount = rdbResult.rowCount;
    diagnostics.rdbParsedCount = rdbResult.items.length;
    diagnostics.rdbInvalidRowCount = rdbResult.invalidRowCount;
    if (rdbResult.items.length > 0) {
      diagnostics.rdbPrimaryReadUsed = true;
      return { items: rdbResult.items, diagnostics };
    }
    if (rdbResult.rowCount > 0 && rdbResult.invalidRowCount > 0) {
      throw new Error('RDB raw_document_json 解析失败');
    }
    if (preferenceItems.length > 0) {
      diagnostics.rdbMigrationAttempted = true;
      rdb.migrate(preferenceItems);
      rdbResult = rdb.listWithDiagnostics();
      diagnostics.rdbRowCount = rdbResult.rowCount;
      diagnostics.rdbParsedCount = rdbResult.items.length;
      diagnostics.rdbInvalidRowCount = rdbResult.invalidRowCount;
      if (rdbResult.items.length > 0) {
        diagnostics.rdbPrimaryReadUsed = true;
        return { items: rdbResult.items, diagnostics };
      }
    }
  } catch (error) {
    diagnostics.rdbErrorMessage = `${error}`;
  }

  diagnostics.rdbFallbackUsed = true;
  return {
    items: legacyLoad(preferenceItems, backupItems),
    diagnostics
  };
}

const rdbPrimary = new InMemoryRdb();
for (const item of [
  createItem('旧 Preferences 记录', 1700000000001, 1700000000001),
  createItem('RDB 最新记录', 1700000000002, 1700000000300)
]) {
  rdbPrimary.rows.set(getReviewDocumentKey(item.document), {
    id: getReviewDocumentKey(item.document),
    updatedAt: item.document.updatedAt,
    createdAt: item.document.createdAt,
    exportedPath: item.exportedPath,
    rawDocumentJson: JSON.stringify(item.document),
    isDeleted: 0
  });
}
const rdbPrimaryResult = loadMainRead({
  rdb: rdbPrimary,
  preferenceItems: [createItem('不应作为主列表', 1700000000999, 1700000000999)]
});
assert(rdbPrimaryResult.items.length === 2, 'RDB has rows: load should return RDB records.');
assert(rdbPrimaryResult.items[0].document.content.title === 'RDB 最新记录', 'RDB rows should keep updatedAt desc order.');
assert(rdbPrimaryResult.diagnostics.rdbPrimaryReadUsed === true, 'RDB primary read should be marked as used.');
assert(rdbPrimary.migrationCount === 0, 'RDB primary hit must not run migration during load.');

const preferenceItem = createItem('Preferences 待迁移记录', 1700000000100, 1700000000200);
const rdbEmpty = new InMemoryRdb();
const migrationResult = loadMainRead({
  rdb: rdbEmpty,
  preferenceItems: [preferenceItem]
});
assert(migrationResult.items.length === 1, 'Empty RDB + Preferences records: load should return migrated RDB record.');
assert(migrationResult.items[0].document.content.title === 'Preferences 待迁移记录', 'Migrated item should preserve title.');
assert(rdbEmpty.migrationCount === 1, 'Empty RDB should trigger exactly one migration on first load.');
const secondMigrationResult = loadMainRead({
  rdb: rdbEmpty,
  preferenceItems: [preferenceItem]
});
assert(secondMigrationResult.items.length === 1, 'Second load should still return the RDB record.');
assert(rdbEmpty.migrationCount === 1, 'Second load with RDB rows must not repeat migration.');
assert(rdbEmpty.rows.size === 1, 'Repeated load must not duplicate migrated rows.');

const fallbackItem = createItem('旧链路回退记录', 1700000000500, 1700000000600);
const failingRdb = new InMemoryRdb({ failQuery: true });
const fallbackResult = loadMainRead({
  rdb: failingRdb,
  preferenceItems: [fallbackItem]
});
assert(fallbackResult.items.length === 1, 'RDB failure must fall back to legacy records.');
assert(fallbackResult.items[0].document.content.title === '旧链路回退记录', 'Fallback should not return an empty library.');
assert(fallbackResult.diagnostics.rdbFallbackUsed === true, 'RDB failure should mark fallback as used.');
assert(fallbackResult.diagnostics.rdbErrorMessage.includes('模拟 RDB query 失败'), 'Fallback diagnostics should retain RDB error.');

const corruptedRdb = new InMemoryRdb();
corruptedRdb.rows.set('broken', {
  id: 'broken',
  updatedAt: 1700000000800,
  createdAt: 1700000000800,
  exportedPath: '',
  rawDocumentJson: '{broken',
  isDeleted: 0
});
const corruptFallbackResult = loadMainRead({
  rdb: corruptedRdb,
  preferenceItems: [fallbackItem]
});
assert(corruptFallbackResult.items.length === 1, 'Broken raw_document_json should fall back to legacy records.');
assert(corruptFallbackResult.diagnostics.rdbFallbackUsed === true, 'Broken raw_document_json should mark fallback as used.');
assert(corruptFallbackResult.diagnostics.rdbInvalidRowCount === 1, 'Broken raw_document_json should be counted.');

const recoveryBackupItem = createItem('review_exchange 恢复记录', 1700000000700, 1700000000700);
const emptyEverythingResult = loadMainRead({
  rdb: new InMemoryRdb(),
  preferenceItems: [],
  backupItems: [recoveryBackupItem]
});
assert(emptyEverythingResult.items.length === 1, 'When RDB and Preferences are empty, legacy review_exchange recovery remains available.');
assert(emptyEverythingResult.items[0].document.content.title === 'review_exchange 恢复记录', 'review_exchange fallback record should be visible.');
assert(emptyEverythingResult.diagnostics.rdbMigrationAttempted === false, 'Empty Preferences should not trigger repeated no-op migration.');

const collisionRdb = new InMemoryRdb();
const sameTimeItems = [
  createItem('同一 createdAt A', 1700000000900, 1700000000901),
  createItem('同一 createdAt B', 1700000000900, 1700000000902)
];
const collisionResult = loadMainRead({
  rdb: collisionRdb,
  preferenceItems: sameTimeItems
});
assert(collisionResult.items.length === 2, 'Migration should preserve createdAt collisions by resolving ids.');
assert(new Set([...collisionRdb.rows.keys()]).size === 2, 'Resolved ids should be unique under createdAt collision.');

if (failed) {
  process.exit(1);
}

console.log('review library RDB phase 3 main-read: RDB hit, migration, fallback, broken raw JSON, no duplicate migration verified');
