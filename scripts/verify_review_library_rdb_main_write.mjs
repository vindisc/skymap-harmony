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
assert(historyServiceSource.includes('persistPreferencesFallbackMirror'), 'Phase 4 should keep a short-term Preferences fallback mirror.');
assert(historyServiceSource.includes('RDB_MAIN_INDEX_READY_KEY'), 'Phase 4 should mark RDB main index readiness.');

const saveBody = extractMethodBody(historyServiceSource, 'static async saveDocument');
assert(saveBody.includes('ReviewCardRdbService.upsertReview'), 'saveDocument must write RDB.');
assert(saveBody.includes('writeRecoverableBackup'), 'saveDocument must write review_exchange backup.');
assert(saveBody.includes('persistLegacySave'), 'saveDocument must fall back to legacy Preferences write if RDB fails.');
assert(saveBody.includes('ReviewCardHistoryService.load(context)'), 'saveDocument should return the RDB-backed load result after success.');

const updateBody = extractMethodBody(historyServiceSource, 'static async updateDocument');
assert(updateBody.includes('ReviewCardRdbService.getReview'), 'updateDocument should preserve existing exportedPath from RDB.');
assert(updateBody.includes('ReviewCardRdbService.upsertReview'), 'updateDocument must update RDB raw_document_json and index columns.');
assert(updateBody.includes('writeRecoverableBackup'), 'updateDocument must refresh review_exchange backup.');
assert(updateBody.includes('persistLegacyUpdate'), 'updateDocument must fall back to legacy Preferences update if RDB fails.');

const markExportedBody = extractMethodBody(historyServiceSource, 'static async markExported');
assert(markExportedBody.includes('ReviewCardRdbService.markExported'), 'markExported must update RDB exported_path.');
assert(markExportedBody.includes('ReviewCardRdbService.upsertReview'), 'markExported must create an RDB row if missing.');
assert(markExportedBody.includes('persistLegacyMarkExported'), 'markExported must fall back to legacy Preferences export mark if RDB fails.');

const deleteBody = extractMethodBody(historyServiceSource, 'static async deleteDocument');
assert(deleteBody.includes('ReviewCardRdbService.deleteReview'), 'deleteDocument must hard delete from RDB.');
assert(deleteBody.includes('deleteRecoverableBackup'), 'deleteDocument must delete sandbox review_exchange backup.');
assert(deleteBody.includes('persistLegacyDelete'), 'deleteDocument must fall back to legacy Preferences delete if RDB fails.');
assert(!deleteBody.includes('is_deleted'), 'deleteDocument must keep phase 4 hard delete semantics.');

assert(!projectDetailSource.includes('ReviewCardRdbService'), 'ProjectDetailPage must not directly call RDB.');
assert(!homePageSource.includes('ReviewCardRdbService'), 'HomePage must not directly call RDB.');
assert(!previewPageSource.includes('ReviewCardRdbService'), 'PreviewPage must not directly call RDB.');
assert(!myPageSource.includes('ReviewCardRdbService'), 'MyPage must not directly call RDB outside diagnostics service.');
assert(!reviewModelSource.includes('reviewId'), 'ReviewCardDocument fields must not be changed for phase 4.');

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
      this.preferences = buildSavedItems(existingItems, document);
      return this.load();
    } catch (error) {
      this.preferences = buildSavedItems(this.preferences, document);
      this.backups.add(getReviewDocumentKey(document));
      return sortItems(this.preferences.map(cloneItem));
    }
  }

  updateDocument(document) {
    try {
      const key = getReviewDocumentKey(document);
      const existingItem = this.rdb.get(key);
      this.rdb.upsert(createItemFromDocument(document, existingItem ? existingItem.exportedPath : ''));
      this.rdbReady = true;
      this.backups.add(key);
      this.preferences = this.load();
      return this.load();
    } catch (error) {
      this.preferences = this.preferences.map((item) => {
        return getReviewDocumentKey(item.document) === getReviewDocumentKey(document)
          ? createItemFromDocument(document, item.exportedPath)
          : cloneItem(item);
      });
      this.backups.add(getReviewDocumentKey(document));
      return sortItems(this.preferences.map(cloneItem));
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
      this.preferences = this.load();
      return this.load();
    } catch (error) {
      this.preferences = markExportedInItems(this.preferences, document, exportedPath);
      return sortItems(this.preferences.map(cloneItem));
    }
  }

  deleteDocument(document) {
    try {
      const key = getReviewDocumentKey(document);
      this.rdb.delete(key);
      this.rdbReady = true;
      this.backups.delete(key);
      this.preferences = this.load();
      return this.load();
    } catch (error) {
      const key = getReviewDocumentKey(document);
      this.preferences = this.preferences.filter((item) => getReviewDocumentKey(item.document) !== key);
      this.backups.delete(key);
      return sortItems(this.preferences.map(cloneItem));
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

function buildSavedItems(items, document) {
  const key = getReviewDocumentKey(document);
  const existingItem = items.find((item) => getReviewDocumentKey(item.document) === key);
  const nextItems = [createItemFromDocument(document, existingItem ? existingItem.exportedPath : '')];
  for (const item of items) {
    if (getReviewDocumentKey(item.document) !== key) {
      nextItems.push(cloneItem(item));
    }
  }
  return sortItems(nextItems);
}

function markExportedInItems(items, document, exportedPath) {
  const key = getReviewDocumentKey(document);
  let found = false;
  const nextItems = items.map((item) => {
    if (getReviewDocumentKey(item.document) === key) {
      found = true;
      return createItemFromDocument(document, exportedPath);
    }
    return cloneItem(item);
  });
  if (!found) {
    nextItems.unshift(createItemFromDocument(document, exportedPath));
  }
  return sortItems(nextItems);
}

const store = new InMemoryHistoryStore();
const savedDocument = createItem('新保存记录', 1700000001000, 1700000001000).document;
const saveResult = store.saveDocument(savedDocument);
assert(store.rdb.get('1700000001000'), 'saveDocument should write a new RDB row.');
assert(store.rdb.get('1700000001000').document.content.title === '新保存记录', 'saveDocument should preserve raw_document_json.');
assert(store.backups.has('1700000001000'), 'saveDocument should write review_exchange backup.');
assert(saveResult.some((item) => item.document.content.title === '新保存记录'), 'save then load should return the RDB record immediately.');

const updatedDocument = cloneDocument(savedDocument);
updatedDocument.content.title = '更新后的记录';
updatedDocument.content.currentBlocker = '新的卡点';
updatedDocument.updatedAt = 1700000002000;
const updateResult = store.updateDocument(updatedDocument);
assert(store.rdb.get('1700000001000').document.content.title === '更新后的记录', 'updateDocument should update raw_document_json.');
assert(store.rdb.get('1700000001000').document.content.currentBlocker === '新的卡点', 'updateDocument should update indexed source fields.');
assert(updateResult[0].document.content.title === '更新后的记录', 'update then load should return updated RDB content.');

const missingUpdateStore = new InMemoryHistoryStore();
const missingUpdateDocument = createItem('缺失时更新补写', 1700000001500, 1700000001501).document;
missingUpdateStore.updateDocument(missingUpdateDocument);
assert(missingUpdateStore.rdb.get('1700000001500'), 'updateDocument should upsert an RDB row when the index is missing.');

const exportResult = store.markExported(updatedDocument, '/data/storage/el2/base/files/review_exports/exported.jpg');
assert(store.rdb.get('1700000001000').exportedPath === '/data/storage/el2/base/files/review_exports/exported.jpg', 'markExported should update RDB exported_path.');
assert(exportResult[0].exportedPath === '/data/storage/el2/base/files/review_exports/exported.jpg', 'markExported then load should expose exportedPath.');

const deleteResult = store.deleteDocument(updatedDocument);
assert(!store.rdb.get('1700000001000'), 'deleteDocument should hard delete the RDB row.');
assert(!store.backups.has('1700000001000'), 'deleteDocument should delete review_exchange backup.');
assert(deleteResult.every((item) => getReviewDocumentKey(item.document) !== '1700000001000'), 'delete then load should not return the deleted record.');

const failingDocument = createItem('失败回退记录', 1700000003000, 1700000003000).document;
const failingStore = new InMemoryHistoryStore({ rdb: new InMemoryRdb({ failWrite: true }) });
const fallbackSaveResult = failingStore.saveDocument(failingDocument);
assert(fallbackSaveResult.length === 1, 'RDB write failure should still return the saved legacy record.');
assert(fallbackSaveResult[0].document.content.title === '失败回退记录', 'RDB write failure must not drop user data.');
assert(failingStore.backups.has('1700000003000'), 'Fallback save should still write review_exchange backup.');

if (failed) {
  process.exit(1);
}

console.log('review library RDB phase 4 main-write: save/update/delete/markExported, backups, immediate RDB load, fallback verified');
