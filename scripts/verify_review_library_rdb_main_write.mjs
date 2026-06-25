import fs from 'node:fs';

const historyServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardHistoryService.ets', 'utf8');
const projectDetailSource = fs.readFileSync('entry/src/main/ets/pages/ProjectDetailPage.ets', 'utf8');
const homePageSource = fs.readFileSync('entry/src/main/ets/pages/HomePage.ets', 'utf8');
const previewPageSource = fs.readFileSync('entry/src/main/ets/pages/PreviewPage.ets', 'utf8');
const myPageSource = fs.readFileSync('entry/src/main/ets/pages/MyPage.ets', 'utf8');
const reviewModelSource = fs.readFileSync('entry/src/main/ets/model/ReviewCardModel.ets', 'utf8');

let failed = false;

function assert(condition, message) {
  if (!condition) {
    failed = true;
    console.error(message);
  }
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

assert(historyServiceSource.includes('ReviewCardRdbService.upsertReview(context'), 'save/update should upsert RDB rows.');
assert(historyServiceSource.includes('ReviewCardRdbService.deleteReview(context'), 'deleteDocument should delete RDB rows.');
assert(historyServiceSource.includes('ReviewCardRdbService.markExported(context'), 'markExported should update RDB exported_path.');
assert(historyServiceSource.includes('writeRecoverableBackup(context, document)'), 'save/update should keep review_exchange backup writes.');
assert(historyServiceSource.includes('deleteRecoverableBackup(context, document)'), 'deleteDocument should keep review_exchange backup deletion.');
assert(!historyServiceSource.includes('persistPreferencesFallbackMirror'), 'Phase 5 must remove Preferences fallback mirror writes.');
assert(!historyServiceSource.includes('persistLegacySave'), 'Phase 5 must remove legacy Preferences save fallback.');
assert(!historyServiceSource.includes('persistLegacyUpdate'), 'Phase 5 must remove legacy Preferences update fallback.');
assert(!historyServiceSource.includes('persistLegacyMarkExported'), 'Phase 5 must remove legacy Preferences export fallback.');
assert(!historyServiceSource.includes('persistLegacyDelete'), 'Phase 5 must remove legacy Preferences delete fallback.');
assert(!historyServiceSource.includes("store.put(HISTORY_KEY, JSON.stringify"), 'ReviewCardHistoryService must not write Preferences.items.');
assert(historyServiceSource.includes('RDB_MAIN_INDEX_READY_KEY'), 'Phase 5 should keep RDB main index readiness marker.');

const saveBody = extractMethodBody(historyServiceSource, 'static async saveDocument');
assert(saveBody.includes('ReviewCardRdbService.upsertReview'), 'saveDocument must write RDB.');
assert(saveBody.includes('writeRecoverableBackup'), 'saveDocument must write review_exchange backup.');
assert(!saveBody.includes('persistLegacy'), 'saveDocument must not silently fall back to Preferences.');
assert(saveBody.includes('throw createRdbWriteError'), 'saveDocument must surface RDB write failure.');
assert(saveBody.includes('ReviewCardHistoryService.load(context)'), 'saveDocument should return the RDB-backed load result after success.');

const updateBody = extractMethodBody(historyServiceSource, 'static async updateDocument');
assert(updateBody.includes('ReviewCardRdbService.getReview'), 'updateDocument should preserve existing exportedPath from RDB.');
assert(updateBody.includes('ReviewCardRdbService.upsertReview'), 'updateDocument must update RDB raw_document_json and index columns.');
assert(updateBody.includes('writeRecoverableBackup'), 'updateDocument must refresh review_exchange backup.');
assert(!updateBody.includes('persistLegacy'), 'updateDocument must not silently fall back to Preferences.');
assert(updateBody.includes('throw createRdbWriteError'), 'updateDocument must surface RDB write failure.');

const markExportedBody = extractMethodBody(historyServiceSource, 'static async markExported');
assert(markExportedBody.includes('ReviewCardRdbService.markExported'), 'markExported must update RDB exported_path.');
assert(markExportedBody.includes('ReviewCardRdbService.upsertReview'), 'markExported must create an RDB row if missing.');
assert(!markExportedBody.includes('persistLegacy'), 'markExported must not silently fall back to Preferences.');
assert(markExportedBody.includes('throw createRdbWriteError'), 'markExported must surface RDB write failure.');

const deleteBody = extractMethodBody(historyServiceSource, 'static async deleteDocument');
assert(deleteBody.includes('ReviewCardRdbService.deleteReview'), 'deleteDocument must hard delete from RDB.');
assert(deleteBody.includes('deleteRecoverableBackup'), 'deleteDocument must delete sandbox review_exchange backup.');
assert(!deleteBody.includes('persistLegacy'), 'deleteDocument must not silently fall back to Preferences.');
assert(deleteBody.includes('throw createRdbWriteError'), 'deleteDocument must surface RDB write failure.');
assert(!deleteBody.includes('is_deleted'), 'deleteDocument must keep phase 5 hard delete semantics.');

assert(!projectDetailSource.includes('ReviewCardRdbService'), 'ProjectDetailPage must not directly call RDB.');
assert(!homePageSource.includes('ReviewCardRdbService'), 'HomePage must not directly call RDB.');
assert(!previewPageSource.includes('ReviewCardRdbService'), 'PreviewPage must not directly call RDB.');
assert(!myPageSource.includes('ReviewCardRdbService'), 'MyPage must not directly call RDB outside diagnostics service.');
assert(!reviewModelSource.includes('reviewId'), 'ReviewCardDocument fields must not be changed for phase 5.');

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

function getReviewDocumentKey(document) {
  return `${document.createdAt}`;
}

function sortItems(items) {
  return [...items].sort((left, right) => {
    if (right.document.updatedAt !== left.document.updatedAt) {
      return right.document.updatedAt - left.document.updatedAt;
    }
    return right.document.createdAt - left.document.createdAt;
  });
}

function createRow(item) {
  const document = cloneDocument(item.document);
  return {
    id: getReviewDocumentKey(document),
    rawDocumentJson: JSON.stringify(document),
    exportedPath: item.exportedPath || '',
    title: document.content.title,
    decision: document.content.judgement,
    updatedAt: document.updatedAt,
    createdAt: document.createdAt
  };
}

class InMemoryRdb {
  constructor(options = {}) {
    this.rows = new Map();
    this.failWrite = options.failWrite === true;
  }

  upsert(item) {
    if (this.failWrite) {
      throw new Error('模拟 RDB 写入失败');
    }
    this.rows.set(getReviewDocumentKey(item.document), createRow(item));
  }

  get(id) {
    const row = this.rows.get(id);
    if (!row) {
      return undefined;
    }
    return {
      document: cloneDocument(JSON.parse(row.rawDocumentJson)),
      exportedPath: row.exportedPath
    };
  }

  markExported(id, exportedPath) {
    if (this.failWrite) {
      throw new Error('模拟 RDB 导出标记失败');
    }
    const row = this.rows.get(id);
    if (row) {
      row.exportedPath = exportedPath;
      this.rows.set(id, row);
    }
  }

  delete(id) {
    if (this.failWrite) {
      throw new Error('模拟 RDB 删除失败');
    }
    this.rows.delete(id);
  }

  list() {
    return sortItems([...this.rows.values()].map((row) => {
      return {
        document: cloneDocument(JSON.parse(row.rawDocumentJson)),
        exportedPath: row.exportedPath
      };
    }));
  }
}

class InMemoryHistoryStore {
  constructor(options = {}) {
    this.rdb = options.rdb || new InMemoryRdb();
    this.preferences = options.preferences ? options.preferences.map(cloneItem) : [];
    this.backups = new Set();
    this.rdbReady = false;
  }

  load() {
    if (this.rdbReady || this.rdb.rows.size > 0) {
      return this.rdb.list();
    }
    return sortItems(this.preferences.map(cloneItem));
  }

  saveDocument(document) {
    try {
      const existingItems = this.load();
      const existingItem = existingItems.find((item) => getReviewDocumentKey(item.document) === getReviewDocumentKey(document));
      const item = createItemFromDocument(document, existingItem ? existingItem.exportedPath : '');
      this.rdb.upsert(item);
      this.rdbReady = true;
      this.backups.add(getReviewDocumentKey(document));
      return this.load();
    } catch (error) {
      this.backups.add(getReviewDocumentKey(document));
      throw error;
    }
  }

  updateDocument(document) {
    try {
      const key = getReviewDocumentKey(document);
      const existingItem = this.rdb.get(key);
      this.rdb.upsert(createItemFromDocument(document, existingItem ? existingItem.exportedPath : ''));
      this.rdbReady = true;
      this.backups.add(key);
      return this.load();
    } catch (error) {
      this.backups.add(getReviewDocumentKey(document));
      throw error;
    }
  }

  markExported(document, exportedPath) {
    try {
      const key = getReviewDocumentKey(document);
      if (this.rdb.get(key)) {
        this.rdb.markExported(key, exportedPath);
      } else {
        this.rdb.upsert(createItemFromDocument(document, exportedPath));
      }
      this.rdbReady = true;
      return this.load();
    } catch (error) {
      throw error;
    }
  }

  deleteDocument(document) {
    try {
      const key = getReviewDocumentKey(document);
      this.rdb.delete(key);
      this.rdbReady = true;
      this.backups.delete(key);
      return this.load();
    } catch (error) {
      throw error;
    }
  }
}

function cloneItem(item) {
  return {
    document: cloneDocument(item.document),
    exportedPath: item.exportedPath || ''
  };
}

function createItemFromDocument(document, exportedPath = '') {
  return {
    document: cloneDocument(document),
    exportedPath
  };
}

const stalePreferenceItem = createItem('旧 Preferences 残留', 1700000000001, 1700000000001);
const store = new InMemoryHistoryStore({ preferences: [stalePreferenceItem] });
const savedDocument = createItem('新保存记录', 1700000001000, 1700000001000).document;
const saveResult = store.saveDocument(savedDocument);
assert(store.rdb.get('1700000001000'), 'saveDocument should write a new RDB row.');
assert(store.rdb.get('1700000001000').document.content.title === '新保存记录', 'saveDocument should preserve raw_document_json.');
assert(store.backups.has('1700000001000'), 'saveDocument should write review_exchange backup.');
assert(saveResult.some((item) => item.document.content.title === '新保存记录'), 'save then load should return the RDB record immediately.');
assert(saveResult.every((item) => item.document.content.title !== '旧 Preferences 残留'), 'RDB main list must not be polluted by stale Preferences items.');
assert(store.preferences.length === 1 && store.preferences[0].document.content.title === '旧 Preferences 残留', 'saveDocument must not rewrite Preferences.items.');

const updatedDocument = cloneDocument(savedDocument);
updatedDocument.content.title = '更新后的记录';
updatedDocument.content.currentBlocker = '新的卡点';
updatedDocument.updatedAt = 1700000002000;
const updateResult = store.updateDocument(updatedDocument);
assert(store.rdb.get('1700000001000').document.content.title === '更新后的记录', 'updateDocument should update raw_document_json.');
assert(store.rdb.get('1700000001000').document.content.currentBlocker === '新的卡点', 'updateDocument should update indexed source fields.');
assert(updateResult[0].document.content.title === '更新后的记录', 'update then load should return updated RDB content.');
assert(store.preferences[0].document.content.title === '旧 Preferences 残留', 'updateDocument must not rewrite Preferences.items.');

const missingUpdateStore = new InMemoryHistoryStore();
const missingUpdateDocument = createItem('缺失时更新补写', 1700000001500, 1700000001501).document;
missingUpdateStore.updateDocument(missingUpdateDocument);
assert(missingUpdateStore.rdb.get('1700000001500'), 'updateDocument should upsert an RDB row when the index is missing.');

const exportResult = store.markExported(updatedDocument, '/data/storage/el2/base/files/review_exports/exported.jpg');
assert(store.rdb.get('1700000001000').exportedPath === '/data/storage/el2/base/files/review_exports/exported.jpg', 'markExported should update RDB exported_path.');
assert(exportResult[0].exportedPath === '/data/storage/el2/base/files/review_exports/exported.jpg', 'markExported then load should expose exportedPath.');
assert(store.preferences[0].exportedPath === '', 'markExported must not rewrite Preferences.items.');

const deleteResult = store.deleteDocument(updatedDocument);
assert(!store.rdb.get('1700000001000'), 'deleteDocument should hard delete the RDB row.');
assert(!store.backups.has('1700000001000'), 'deleteDocument should delete review_exchange backup.');
assert(deleteResult.every((item) => getReviewDocumentKey(item.document) !== '1700000001000'), 'delete then load should not return the deleted record.');
assert(store.preferences.length === 1 && store.preferences[0].document.content.title === '旧 Preferences 残留', 'deleteDocument must not rewrite Preferences.items.');

const failingDocument = createItem('失败不回退 Preferences', 1700000003000, 1700000003000).document;
const failingStore = new InMemoryHistoryStore({ rdb: new InMemoryRdb({ failWrite: true }) });
let failedSaveThrown = false;
try {
  failingStore.saveDocument(failingDocument);
} catch (error) {
  failedSaveThrown = true;
}
assert(failedSaveThrown, 'RDB write failure should surface instead of returning a Preferences-backed success.');
assert(failingStore.preferences.length === 0, 'RDB write failure must not write Preferences.items.');
assert(failingStore.backups.has('1700000003000'), 'Failed save should still best-effort write review_exchange backup.');

if (failed) {
  process.exit(1);
}

console.log('review library RDB phase 5 main-write: save/update/delete/markExported, backup retention, Preferences retirement, failure surfacing verified');
