import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import formBindingData from '@ohos.app.form.formBindingData';
import formProvider from '@ohos.app.form.formProvider';
import {
  createEmptyLearningProgressSnapshot,
  LearningProgressService,
  LearningProgressSnapshot
} from './LearningProgressService';

const LEARNING_PROGRESS_FORM_PREFERENCES: string = 'learning_progress_form_preferences';
const LEARNING_PROGRESS_FORM_IDS_KEY: string = 'formIds';

export const LEARNING_PROGRESS_WIDGET_ROUTE_HOME: string = 'home';
export const LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING: string = 'library_pending';
export const LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT: string = 'today_review_direct';

export interface LearningProgressFormData {
  title: string;
  pendingCountText: string;
  totalImportedCountText: string;
  completedCountText: string;
  completionRateText: string;
  targetRoute: string;
}

function splitStoredFormIds(value: string): Array<string> {
  if (value.length <= 0) {
    return [];
  }
  return value.split(',').filter((item: string): boolean => item.length > 0);
}

function joinStoredFormIds(ids: Array<string>): string {
  return ids.filter((item: string, index: number): boolean => {
    return item.length > 0 && ids.indexOf(item) === index;
  }).join(',');
}

export class LearningProgressFormService {
  static buildFormData(snapshot: LearningProgressSnapshot): LearningProgressFormData {
    return {
      title: '摄影学习',
      pendingCountText: `${snapshot.pendingCount}`,
      totalImportedCountText: `${snapshot.totalImportedCount}`,
      completedCountText: `${snapshot.completedCount}`,
      completionRateText: snapshot.completionRateText,
      targetRoute: snapshot.pendingCount > 0
        ? LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING
        : LEARNING_PROGRESS_WIDGET_ROUTE_HOME
    };
  }

  static createBindingData(snapshot: LearningProgressSnapshot): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData(LearningProgressFormService.buildFormData(snapshot));
  }

  static createEmptyBindingData(): formBindingData.FormBindingData {
    return LearningProgressFormService.createBindingData(createEmptyLearningProgressSnapshot());
  }

  static async loadSnapshot(context: common.Context): Promise<LearningProgressSnapshot> {
    return await LearningProgressService.load(context as common.UIAbilityContext);
  }

  static async addFormId(context: common.Context, formId: string): Promise<void> {
    if (formId.length <= 0) {
      return;
    }
    const store: preferences.Preferences = await preferences.getPreferences(context, LEARNING_PROGRESS_FORM_PREFERENCES);
    const current: string = await store.get(LEARNING_PROGRESS_FORM_IDS_KEY, '') as string;
    const ids: Array<string> = splitStoredFormIds(current);
    if (ids.indexOf(formId) < 0) {
      ids.push(formId);
      await store.put(LEARNING_PROGRESS_FORM_IDS_KEY, joinStoredFormIds(ids));
      await store.flush();
    }
  }

  static async removeFormId(context: common.Context, formId: string): Promise<void> {
    if (formId.length <= 0) {
      return;
    }
    const store: preferences.Preferences = await preferences.getPreferences(context, LEARNING_PROGRESS_FORM_PREFERENCES);
    const current: string = await store.get(LEARNING_PROGRESS_FORM_IDS_KEY, '') as string;
    const nextIds: Array<string> = splitStoredFormIds(current).filter((item: string): boolean => item !== formId);
    await store.put(LEARNING_PROGRESS_FORM_IDS_KEY, joinStoredFormIds(nextIds));
    await store.flush();
  }

  static async loadFormIds(context: common.Context): Promise<Array<string>> {
    const store: preferences.Preferences = await preferences.getPreferences(context, LEARNING_PROGRESS_FORM_PREFERENCES);
    const current: string = await store.get(LEARNING_PROGRESS_FORM_IDS_KEY, '') as string;
    return splitStoredFormIds(current);
  }

  static async refreshForm(context: common.Context, formId: string): Promise<void> {
    if (formId.length <= 0) {
      return;
    }
    const snapshot: LearningProgressSnapshot = await LearningProgressFormService.loadSnapshot(context);
    await formProvider.updateForm(formId, LearningProgressFormService.createBindingData(snapshot));
  }

  static async refreshAllForms(context: common.Context): Promise<void> {
    const ids: Array<string> = await LearningProgressFormService.loadFormIds(context);
    if (ids.length <= 0) {
      return;
    }
    const snapshot: LearningProgressSnapshot = await LearningProgressFormService.loadSnapshot(context);
    const bindingData: formBindingData.FormBindingData = LearningProgressFormService.createBindingData(snapshot);
    for (let index = 0; index < ids.length; index += 1) {
      try {
        await formProvider.updateForm(ids[index], bindingData);
      } catch (error) {
        console.warn(`[LearningProgressFormService] 服务卡片刷新失败：${ids[index]}, ${error}`);
      }
    }
  }
}
