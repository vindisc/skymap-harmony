import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { SettingsRefreshService } from './SettingsRefreshService';

const PREFERENCES_NAME: string = 'review_settings';
const REVIEWER_NAME_KEY: string = 'reviewer_name';
const WIDGET_CARD_BACKGROUND_STYLE_KEY: string = 'widget_card_background_style';

export const REVIEW_WIDGET_CARD_BACKGROUND_PLAIN: string = 'plain';
export const REVIEW_WIDGET_CARD_BACKGROUND_TEXTURE: string = 'texture';

function normalizeReviewerName(value: string | undefined): string {
  if (typeof value !== 'string') {
    return '';
  }

  return value.trim();
}

function normalizeWidgetCardBackgroundStyle(value: string | undefined): string {
  if (value === REVIEW_WIDGET_CARD_BACKGROUND_TEXTURE) {
    return REVIEW_WIDGET_CARD_BACKGROUND_TEXTURE;
  }
  return REVIEW_WIDGET_CARD_BACKGROUND_PLAIN;
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

  static async loadWidgetCardBackgroundStyle(context: common.UIAbilityContext): Promise<string> {
    try {
      const store = await ReviewSettingsService.getStore(context);
      const rawValue = await store.get(WIDGET_CARD_BACKGROUND_STYLE_KEY, REVIEW_WIDGET_CARD_BACKGROUND_PLAIN);
      if (typeof rawValue === 'string') {
        return normalizeWidgetCardBackgroundStyle(rawValue);
      }
      return REVIEW_WIDGET_CARD_BACKGROUND_PLAIN;
    } catch (error) {
      return REVIEW_WIDGET_CARD_BACKGROUND_PLAIN;
    }
  }

  static async saveWidgetCardBackgroundStyle(context: common.UIAbilityContext, style: string): Promise<string> {
    const normalizedStyle: string = normalizeWidgetCardBackgroundStyle(style);
    const store = await ReviewSettingsService.getStore(context);
    await store.put(WIDGET_CARD_BACKGROUND_STYLE_KEY, normalizedStyle);
    await store.flush();
    SettingsRefreshService.notifySettingsChanged('widget_card_background_saved');
    return normalizedStyle;
  }

  static resolveWidgetCardBackgroundLabel(style: string): string {
    return normalizeWidgetCardBackgroundStyle(style) === REVIEW_WIDGET_CARD_BACKGROUND_TEXTURE ? '纹理' : '白色';
  }
}
