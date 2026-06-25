import fs from 'node:fs';

const historyServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardHistoryService.ets', 'utf8');
const migrationServiceSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardMigrationService.ets', 'utf8');
const diagnosticsSource = fs.readFileSync('entry/src/main/ets/services/ReviewCardRdbDiagnosticsService.ets', 'utf8');

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

assert(migrationServiceSource.includes("const PREFERENCES_NAME: string = 'review_card_history';"), 'Migration service must keep legacy Preferences source.');
assert(migrationServiceSource.includes("const HISTORY_KEY: string = 'items';"), 'Migration service must keep legacy items key.');
assert(migrationServiceSource.includes('migrateFromPreferencesToRdb'), 'Preferences to RDB migration must remain available.');
assert(migrationServiceSource.includes('countPreferenceHistoryItems'), 'Migration source count must remain available.');
assert(diagnosticsSource.includes('runMigrationDiagnostics'), 'Migration diagnostics must remain available.');

assert(!historyServiceSource.includes('persistPreferencesFallbackMirror'), 'History service must not keep Preferences mirror writer.');
assert(!historyServiceSource.includes('persistLegacySave'), 'History service must not keep legacy save writer.');
assert(!historyServiceSource.includes('persistLegacyUpdate'), 'History service must not keep legacy update writer.');
assert(!historyServiceSource.includes('persistLegacyMarkExported'), 'History service must not keep legacy exported writer.');
assert(!historyServiceSource.includes('persistLegacyDelete'), 'History service must not keep legacy delete writer.');
assert(!historyServiceSource.includes('store.put(HISTORY_KEY, JSON.stringify'), 'History service must not write Preferences.items.');

const loadFromRdbBody = extractMethodBody(historyServiceSource, 'private static async loadFromRdbWithDiagnostics');
assert(loadFromRdbBody.includes('if (rdbResult.items.length > 0)'), 'RDB rows should be the first successful load result.');
assert(loadFromRdbBody.indexOf('if (rdbResult.items.length > 0)') < loadFromRdbBody.indexOf('countPreferenceHistoryItems'), 'RDB non-empty load must return before Preferences migration.');
assert(loadFromRdbBody.includes('isRdbMainIndexReady(context)'), 'RDB ready marker must prevent repeated Preferences migration after phase 5.');
assert(loadFromRdbBody.includes('migrateFromPreferencesToRdb(context)'), 'RDB empty and not-ready path must still migrate old Preferences data.');

const loadLegacyBody = extractMethodBody(historyServiceSource, 'private static async loadLegacyWithDiagnostics');
assert(loadLegacyBody.includes('store.get(HISTORY_KEY'), 'Legacy fallback must still read Preferences for old data and diagnostics.');
assert(loadLegacyBody.includes('loadBackupItemsOnce'), 'Legacy fallback must still use review_exchange limited recovery.');
assert(loadLegacyBody.includes('migrateRecoveredBackupItemsToRdb'), 'review_exchange recovery should migrate into RDB instead of writing Preferences.');
assert(!loadLegacyBody.includes('persist(context'), 'Legacy fallback must not persist merged records back to Preferences.');

for (const methodName of ['saveDocument', 'updateDocument', 'markExported', 'deleteDocument']) {
  const body = extractMethodBody(historyServiceSource, `static async ${methodName}`);
  assert(body.includes('ReviewCardRdbService.'), `${methodName} must use RDB as main write target.`);
  assert(!body.includes('persistLegacy'), `${methodName} must not fall back to legacy Preferences writer.`);
  assert(!body.includes('persistPreferencesFallbackMirror'), `${methodName} must not mirror to Preferences.`);
  assert(body.includes('throw createRdbWriteError'), `${methodName} must surface RDB write failure.`);
}

class StoreModel {
  constructor() {
    this.rdb = new Map();
    this.preferences = [];
    this.backups = new Map();
    this.rdbReady = false;
    this.migrationCount = 0;
  }

  load() {
    if (this.rdb.size > 0) {
      return [...this.rdb.values()];
    }
    if (this.rdbReady) {
      return [];
    }
    if (this.preferences.length > 0) {
      this.migrationCount += 1;
      for (const item of this.preferences) {
        this.rdb.set(item.id, item);
      }
      this.rdbReady = true;
      return [...this.rdb.values()];
    }
    if (this.backups.size > 0) {
      for (const item of this.backups.values()) {
        this.rdb.set(item.id, item);
      }
      this.rdbReady = true;
      return [...this.rdb.values()];
    }
    return [];
  }

  save(item) {
    this.rdb.set(item.id, item);
    this.backups.set(item.id, item);
    this.rdbReady = true;
    return this.load();
  }

  markExported(id, exportedPath) {
    const item = this.rdb.get(id);
    this.rdb.set(id, { ...item, exportedPath });
    return this.load();
  }

  delete(id) {
    this.rdb.delete(id);
    this.backups.delete(id);
    this.rdbReady = true;
    return this.load();
  }
}

const store = new StoreModel();
store.preferences.push({ id: 'legacy', title: 'Preferences 残留', exportedPath: '' });
store.save({ id: 'rdb', title: 'RDB 主索引', exportedPath: '' });
assert(store.load().length === 1 && store.load()[0].id === 'rdb', 'RDB non-empty load must not merge stale Preferences items.');
assert(store.preferences.length === 1 && store.preferences[0].id === 'legacy', 'save must not rewrite Preferences.items.');
store.markExported('rdb', '/exports/rdb.jpg');
assert(store.preferences[0].exportedPath === '', 'markExported must not rewrite Preferences.items.');
store.delete('rdb');
assert(store.preferences.length === 1 && store.preferences[0].id === 'legacy', 'delete must not rewrite Preferences.items.');

const migrationStore = new StoreModel();
migrationStore.preferences.push({ id: 'old', title: '旧版本 Preferences', exportedPath: '' });
assert(migrationStore.load()[0].id === 'old', 'RDB empty path should migrate old Preferences data.');
assert(migrationStore.migrationCount === 1, 'First empty RDB load should migrate once.');
assert(migrationStore.load()[0].id === 'old', 'Second load should return migrated RDB data.');
assert(migrationStore.migrationCount === 1, 'Second load should not duplicate migration.');

const backupRecoveryStore = new StoreModel();
backupRecoveryStore.backups.set('backup', { id: 'backup', title: 'review_exchange 恢复', exportedPath: '' });
assert(backupRecoveryStore.load()[0].id === 'backup', 'review_exchange remains available as limited recovery.');
assert(backupRecoveryStore.rdb.has('backup'), 'review_exchange recovery should populate RDB.');

if (failed) {
  process.exit(1);
}

console.log('review library RDB phase 5: Preferences.items retired from main writes, migration and review_exchange recovery retained');
