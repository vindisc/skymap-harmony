import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { SettingsRefreshService } from './SettingsRefreshService';

const PREFERENCES_NAME: string = 'review_settings';
const REVIEWER_NAME_KEY: string = 'reviewer_name';

function normalizeReviewerName(value: string | undefined): string {
  if (typeof value !== 'string') {
    return '';
  }

  return value.trim();
}

export class ReviewSettingsService {
  private static async getStore(context: common.UIAbilityContext): Promise<preferences.Preferences> {
    return preferences.getPreferences(context, { name: PREFERENCES_NAME });
  }

  static async loadReviewerName(context: common.UIAbilityContext): Promise<string> {
    try {
      const store = await ReviewSettingsService.getStore(context);
      const rawValue = await store.get(REVIEWER_NAME_KEY, '');
      if (typeof rawValue === 'string') {
        return normalizeReviewerName(rawValue);
      }
      return '';
    } catch (error) {
      return '';
    }
  }

  static async saveReviewerName(context: common.UIAbilityContext, reviewerName: string): Promise<string> {
    const normalizedName = normalizeReviewerName(reviewerName);
    const store = await ReviewSettingsService.getStore(context);
    await store.put(REVIEWER_NAME_KEY, normalizedName);
    await store.flush();
    SettingsRefreshService.notifySettingsChanged('reviewer_name_saved');
    return normalizedName;
  }
}
