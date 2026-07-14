import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { SettingsRefreshService } from './SettingsRefreshService';

const PREFERENCES_NAME: string = 'review_settings';
const REVIEWER_NAME_KEY: string = 'reviewer_name';
const WIDGET_CARD_BACKGROUND_STYLE_KEY: string = 'widget_card_background_style';
const SHATTER_ANIMATION_ENABLED_KEY: string = 'shatter_animation_enabled';
const MOTION_QUALITY_KEY: string = 'motion_quality';
const REVIEW_STREAK_RECORD_KEY: string = 'review_streak_record';

export const REVIEW_WIDGET_CARD_BACKGROUND_PLAIN: string = 'plain';
export const REVIEW_WIDGET_CARD_BACKGROUND_HUIWEN: string = 'huiwen';
export const REVIEW_WIDGET_CARD_BACKGROUND_HUIWEN_CORNER: string = 'huiwen_corner';
export const SHATTER_ANIMATION_DEFAULT: boolean = true;

export enum MotionQuality {
  FULL = 'full',
  CALM = 'calm',
  MINIMAL = 'minimal'
}

function normalizeMotionQuality(value: string | undefined): MotionQuality {
  if (value === MotionQuality.CALM) {
    return MotionQuality.CALM;
  }
  if (value === MotionQuality.MINIMAL) {
    return MotionQuality.MINIMAL;
  }
  return MotionQuality.FULL;
}

function normalizeReviewerName(value: string | undefined): string {
  if (typeof value !== 'string') {
    return '';
  }

  return value.trim();
}

function normalizeWidgetCardBackgroundStyle(value: string | undefined): string {
  const supportedStyles: Array<string> = [
    REVIEW_WIDGET_CARD_BACKGROUND_PLAIN,
    REVIEW_WIDGET_CARD_BACKGROUND_HUIWEN,
    REVIEW_WIDGET_CARD_BACKGROUND_HUIWEN_CORNER
  ];
  if (value !== undefined && supportedStyles.includes(value)) {
    return value;
  }
  return REVIEW_WIDGET_CARD_BACKGROUND_PLAIN;
}

export class ReviewSettingsService {
  private static async getStore(context: common.UIAbilityContext): Promise<preferences.Preferences> {
    try {
      return await preferences.getPreferences(context, { name: PREFERENCES_NAME });
    } catch (error) {
      throw new Error(`打开复盘设置失败：${error}`);
    }
  }

  private static async persistValue(
    store: preferences.Preferences,
    key: string,
    value: preferences.ValueType
  ): Promise<void> {
    try {
      await store.put(key, value);
      await store.flush();
    } catch (error) {
      throw new Error(`保存复盘设置 ${key} 失败：${error}`);
    }
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
    await ReviewSettingsService.persistValue(store, REVIEWER_NAME_KEY, normalizedName);
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
    await ReviewSettingsService.persistValue(store, WIDGET_CARD_BACKGROUND_STYLE_KEY, normalizedStyle);
    SettingsRefreshService.notifySettingsChanged('widget_card_background_saved');
    return normalizedStyle;
  }

  static resolveWidgetCardBackgroundLabel(style: string): string {
    const normalizedStyle: string = normalizeWidgetCardBackgroundStyle(style);
    if (normalizedStyle === REVIEW_WIDGET_CARD_BACKGROUND_HUIWEN) {
      return '密集回纹';
    }
    if (normalizedStyle === REVIEW_WIDGET_CARD_BACKGROUND_HUIWEN_CORNER) {
      return '回纹角花';
    }
    return '素纸';
  }

  static async loadShatterAnimationEnabled(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const store = await ReviewSettingsService.getStore(context);
      const rawValue = await store.get(SHATTER_ANIMATION_ENABLED_KEY, SHATTER_ANIMATION_DEFAULT ? 'true' : 'false');
      return String(rawValue) !== 'false';
    } catch (error) {
      return SHATTER_ANIMATION_DEFAULT;
    }
  }

  static async saveShatterAnimationEnabled(context: common.UIAbilityContext, enabled: boolean): Promise<boolean> {
    const store = await ReviewSettingsService.getStore(context);
    await ReviewSettingsService.persistValue(store, SHATTER_ANIMATION_ENABLED_KEY, enabled ? 'true' : 'false');
    SettingsRefreshService.notifySettingsChanged('shatter_animation_saved');
    return enabled;
  }

  static async loadMotionQuality(context: common.UIAbilityContext): Promise<MotionQuality> {
    try {
      const store = await ReviewSettingsService.getStore(context);
      const rawValue = await store.get(MOTION_QUALITY_KEY, MotionQuality.FULL);
      return normalizeMotionQuality(String(rawValue));
    } catch (error) {
      return MotionQuality.FULL;
    }
  }

  static async saveMotionQuality(
    context: common.UIAbilityContext,
    value: MotionQuality
  ): Promise<MotionQuality> {
    const normalizedValue: MotionQuality = normalizeMotionQuality(value);
    const store = await ReviewSettingsService.getStore(context);
    await ReviewSettingsService.persistValue(store, MOTION_QUALITY_KEY, normalizedValue);
    SettingsRefreshService.notifySettingsChanged('motion_quality_saved');
    return normalizedValue;
  }

  static async updateReviewStreakRecord(
    context: common.UIAbilityContext,
    streakDays: number
  ): Promise<boolean> {
    const normalizedStreakDays: number = Math.max(0, Math.floor(streakDays));
    if (normalizedStreakDays < 2) {
      return false;
    }
    try {
      const store = await ReviewSettingsService.getStore(context);
      const rawValue = await store.get(REVIEW_STREAK_RECORD_KEY, 0);
      const previousRecord: number = typeof rawValue === 'number' && Number.isFinite(rawValue)
        ? Math.max(0, Math.floor(rawValue))
        : 0;
      if (normalizedStreakDays <= previousRecord) {
        return false;
      }
      await ReviewSettingsService.persistValue(store, REVIEW_STREAK_RECORD_KEY, normalizedStreakDays);
      return true;
    } catch (error) {
      console.warn(`[ReviewSettingsService] 保存连续复盘纪录失败：${error}`);
      return false;
    }
  }

  static resolveMotionQualityLabel(value: MotionQuality): string {
    if (value === MotionQuality.CALM) {
      return '舒缓';
    }
    if (value === MotionQuality.MINIMAL) {
      return '最少';
    }
    return '完整';
  }
}
