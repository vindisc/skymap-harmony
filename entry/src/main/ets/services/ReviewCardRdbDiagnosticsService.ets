import common from '@ohos.app.ability.common';
import {
  createDefaultReviewCardDocument,
  ReviewCardDocument,
  ReviewCardHistoryItem,
  ReviewJudgementStatus
} from '../model/ReviewCardModel';
import { ReviewCardMigrationService, MigrationResult, MigrationVerifyResult } from './ReviewCardMigrationService';
import { ReviewCardRdbService } from './ReviewCardRdbService';
import { ReviewCardRdbRow, ReviewLibraryStats } from './ReviewCardRdbModel';

export interface RdbDiagnosticsStep {
  name: string;
  success: boolean;
  message: string;
}

export interface RdbDiagnosticsResult {
  success: boolean;
  steps: Array<RdbDiagnosticsStep>;
  insertedId?: string;
  errors: Array<string>;
}

export interface RdbMigrationDiagnosticsResult extends RdbDiagnosticsResult {
  preferencesCount: number;
  rdbCount: number;
  migrationResult: MigrationResult;
  verifyResult: MigrationVerifyResult;
}

const DIAGNOSTIC_ID_PREFIX: string = 'diagnostic_review_rdb_';

function createDiagnosticsResult(insertedId?: string): RdbDiagnosticsResult {
  return {
    success: false,
    steps: [],
    insertedId: insertedId,
    errors: []
  };
}

function appendStep(result: RdbDiagnosticsResult, name: string, success: boolean, message: string): void {
  result.steps.push({
    name: name,
    success: success,
    message: message
  });
  if (!success) {
    result.errors.push(`${name}: ${message}`);
  }
}

function assertStep(result: RdbDiagnosticsResult, name: string, condition: boolean, successMessage: string, failureMessage: string): void {
  appendStep(result, name, condition, condition ? successMessage : failureMessage);
}

function createDiagnosticDocument(
  title: string,
  judgement: ReviewJudgementStatus,
  createdAt: number,
  updatedAt: number
): ReviewCardDocument {
  const document: ReviewCardDocument = createDefaultReviewCardDocument();
  document.projectId = 'rdb_diagnostics';
  document.imageUri = `/data/storage/el2/base/files/${title}.jpg`;
  document.imageWidth = 1200;
  document.imageHeight = 800;
  document.content.title = title;
  document.content.visualFocus = '设备侧RDB落点';
  document.content.focusReason = '验证关键词搜索与映射';
  document.content.visualPath = '诊断记录到RDB再读回';
  document.content.visibleFacts = 'ArkData RDB 旁路验证';
  document.content.coreRelation = '诊断记录与本地数据库';
  document.content.judgement = judgement;
  document.content.currentBlocker = '仅开发期调用';
  document.createdAt = createdAt;
  document.updatedAt = updatedAt;
  return document;
}

function createDiagnosticItem(
  title: string,
  judgement: ReviewJudgementStatus,
  createdAt: number,
  updatedAt: number,
  exportedPath: string
): ReviewCardHistoryItem {
  return {
    document: createDiagnosticDocument(title, judgement, createdAt, updatedAt),
    exportedPath: exportedPath
  };
}

export class ReviewCardRdbDiagnosticsService {
  static async runRdbDiagnostics(context: common.UIAbilityContext): Promise<RdbDiagnosticsResult> {
    const now: number = Date.now();
    const primaryId: string = `${DIAGNOSTIC_ID_PREFIX}${now}`;
    const secondaryId: string = `${DIAGNOSTIC_ID_PREFIX}${now}_older`;
    const exportedPath: string = `/data/storage/el2/base/files/review_exports/${primaryId}.jpg`;
    const nextExportedPath: string = `/data/storage/el2/base/files/review_exports/${primaryId}_updated.jpg`;
    const result: RdbDiagnosticsResult = createDiagnosticsResult(primaryId);
    const primaryItem: ReviewCardHistoryItem = createDiagnosticItem(
      'RDB设备侧诊断主记录',
      ReviewJudgementStatus.VALID,
      now,
      now + 2000,
      exportedPath
    );
    const secondaryItem: ReviewCardHistoryItem = createDiagnosticItem(
      'RDB设备侧诊断旧记录',
      ReviewJudgementStatus.INVALID,
      now - 1000,
      now + 1000,
      ''
    );

    try {
      await ReviewCardRdbService.init(context);
      appendStep(result, 'init', true, 'RDB 初始化与 reviews 表结构创建完成');

      const statsBefore: ReviewLibraryStats = await ReviewCardRdbService.getStats(context);
      await ReviewCardRdbService.upsertReview(context, secondaryItem, secondaryId);
      await ReviewCardRdbService.upsertReview(context, primaryItem, primaryId);
      appendStep(result, 'upsert', true, `已写入诊断记录 ${primaryId} 与 ${secondaryId}`);

      const loadedItem: ReviewCardHistoryItem | undefined = await ReviewCardRdbService.getReview(context, primaryId);
      assertStep(result, 'getReview', loadedItem !== undefined, '按 id 读取成功', '按 id 读取失败');

      if (loadedItem) {
        const diagnosticRows: Array<ReviewCardRdbRow> = await ReviewCardRdbService.listReviewRows(context, {
          keyword: 'RDB设备侧诊断',
          includeDeleted: false
        });
        const primaryRow: ReviewCardRdbRow | undefined = diagnosticRows.find((row: ReviewCardRdbRow): boolean => {
          return row.id === primaryId;
        });
        let rawJsonParsed: boolean = false;
        if (primaryRow) {
          try {
            JSON.parse(primaryRow.rawDocumentJson);
            rawJsonParsed = true;
          } catch (error) {
            rawJsonParsed = false;
          }
        }
        assertStep(result, 'raw_document_json', rawJsonParsed, 'raw_document_json 可恢复为 ReviewCardDocument', 'raw_document_json 解析失败');
        assertStep(
          result,
          'fieldMapping',
          loadedItem.document.imageUri === primaryItem.document.imageUri &&
            loadedItem.document.content.judgement === primaryItem.document.content.judgement &&
            loadedItem.document.updatedAt === primaryItem.document.updatedAt &&
            loadedItem.exportedPath === exportedPath,
          'image_uri / decision / updated_at / exported_path 字段一致',
          '关键字段映射不一致'
        );
      }

      const listedItems: Array<ReviewCardHistoryItem> = await ReviewCardRdbService.listReviews(context, {
        keyword: 'RDB设备侧诊断',
        limit: 2
      });
      assertStep(
        result,
        'listReviews',
        listedItems.length >= 2 && listedItems[0].document.updatedAt >= listedItems[1].document.updatedAt,
        'listReviews 可按 updated_at DESC 返回诊断记录',
        'listReviews 排序或数量不符合预期'
      );

      const validItems: Array<ReviewCardHistoryItem> = await ReviewCardRdbService.listReviews(context, {
        decision: ReviewJudgementStatus.VALID,
        keyword: 'RDB设备侧诊断'
      });
      assertStep(
        result,
        'decisionFilter',
        validItems.some((item: ReviewCardHistoryItem): boolean => item.document.content.title === primaryItem.document.content.title),
        'decision 筛选可命中诊断主记录',
        'decision 筛选未命中诊断主记录'
      );

      const keywordItems: Array<ReviewCardHistoryItem> = await ReviewCardRdbService.listReviews(context, {
        keyword: '本地数据库'
      });
      assertStep(
        result,
        'keywordSearch',
        keywordItems.some((item: ReviewCardHistoryItem): boolean => item.document.content.title === primaryItem.document.content.title),
        'keyword 搜索可命中 coreRelation',
        'keyword 搜索未命中 coreRelation'
      );

      await ReviewCardRdbService.markExported(context, primaryId, nextExportedPath);
      const exportedItem: ReviewCardHistoryItem | undefined = await ReviewCardRdbService.getReview(context, primaryId);
      assertStep(
        result,
        'markExported',
        exportedItem !== undefined && exportedItem.exportedPath === nextExportedPath,
        'markExported 后 exported_path 可读回',
        'markExported 后 exported_path 不一致'
      );

      const statsAfter: ReviewLibraryStats = await ReviewCardRdbService.getStats(context);
      assertStep(
        result,
        'getStats',
        statsAfter.total >= statsBefore.total + 2 &&
          statsAfter.works >= statsBefore.works + 1 &&
          statsAfter.notWorks >= statsBefore.notWorks + 1,
        'getStats 可反映诊断记录增量',
        'getStats 未反映诊断记录增量'
      );

      await ReviewCardRdbService.deleteReview(context, primaryId);
      const deletedItem: ReviewCardHistoryItem | undefined = await ReviewCardRdbService.getReview(context, primaryId);
      assertStep(
        result,
        'deleteReview',
        deletedItem === undefined,
        'deleteReview 硬删除后按 id 不可读',
        'deleteReview 后仍可读取诊断记录'
      );
    } catch (error) {
      appendStep(result, 'exception', false, `${error}`);
    } finally {
      await ReviewCardRdbDiagnosticsService.deleteDiagnosticRecord(context, primaryId, result);
      await ReviewCardRdbDiagnosticsService.deleteDiagnosticRecord(context, secondaryId, result);
      result.success = result.errors.length === 0;
    }

    return result;
  }

  static async runMigrationDiagnostics(context: common.UIAbilityContext): Promise<RdbMigrationDiagnosticsResult> {
    const result = createDiagnosticsResult() as RdbMigrationDiagnosticsResult;
    result.preferencesCount = 0;
    result.rdbCount = 0;
    result.migrationResult = {
      sourceCount: 0,
      insertedCount: 0,
      skippedCount: 0,
      failedCount: 0,
      errors: []
    };
    result.verifyResult = {
      preferencesCount: 0,
      rdbCount: 0,
      missingIds: [],
      rawJsonInvalidCount: 0,
      success: false
    };

    try {
      result.preferencesCount = await ReviewCardMigrationService.countPreferenceHistoryItems(context);
      appendStep(result, 'readPreferences', true, `Preferences 当前历史数量 ${result.preferencesCount}`);

      result.migrationResult = await ReviewCardMigrationService.migrateFromPreferencesToRdb(context);
      appendStep(
        result,
        'migrateFromPreferencesToRdb',
        result.migrationResult.failedCount === 0,
        `source=${result.migrationResult.sourceCount}, inserted=${result.migrationResult.insertedCount}, skipped=${result.migrationResult.skippedCount}`,
        `failed=${result.migrationResult.failedCount}, errors=${result.migrationResult.errors.join('; ')}`
      );

      result.verifyResult = await ReviewCardMigrationService.verifyRdbMigration(context);
      result.rdbCount = result.verifyResult.rdbCount;
      appendStep(
        result,
        'verifyRdbMigration',
        result.verifyResult.success,
        `rdb=${result.verifyResult.rdbCount}, rawJsonInvalid=${result.verifyResult.rawJsonInvalidCount}`,
        `missing=${result.verifyResult.missingIds.join(',')}, rawJsonInvalid=${result.verifyResult.rawJsonInvalidCount}`
      );
    } catch (error) {
      appendStep(result, 'exception', false, `${error}`);
    } finally {
      result.success = result.errors.length === 0;
    }

    return result;
  }

  static formatDiagnosticsResult(result: RdbDiagnosticsResult): string {
    const lines: Array<string> = [
      result.success ? 'RDB诊断通过' : 'RDB诊断失败',
      result.insertedId ? `insertedId=${result.insertedId}` : ''
    ];
    result.steps.forEach((step: RdbDiagnosticsStep): void => {
      lines.push(`${step.success ? 'OK' : 'FAIL'} ${step.name}: ${step.message}`);
    });
    if (result.errors.length > 0) {
      lines.push(`errors=${result.errors.join(' | ')}`);
    }
    return lines.filter((line: string): boolean => line.length > 0).join('\n');
  }

  private static async deleteDiagnosticRecord(context: common.UIAbilityContext, id: string, result: RdbDiagnosticsResult): Promise<void> {
    try {
      await ReviewCardRdbService.deleteReview(context, id);
    } catch (error) {
      appendStep(result, `cleanup:${id}`, false, `${error}`);
    }
  }
}
