import { InsightIntentExecutor, insightIntent } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import {
  FormLaunchIntentService,
  IntentRouteSource
} from '../services/FormLaunchIntentService';
import {
  LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING,
  LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT
} from '../services/LearningProgressFormService';

export const XIAOYI_INTENT_START_PHOTO_REVIEW: string = 'StartPhotoReview';
export const XIAOYI_INTENT_VIEW_PENDING_REVIEWS: string = 'ViewPendingReviews';

export default class PhotoReviewIntentExecutor extends InsightIntentExecutor {
  async onExecuteInUIAbilityForegroundMode(
    intentName: string,
    intentParam: Record<string, Object>,
    pageLoader: window.WindowStage
  ): Promise<insightIntent.ExecuteResult> {
    const route: string = this.resolveRoute(intentName);
    if (route.length > 0) {
      FormLaunchIntentService.captureRouteFromIntent(route, IntentRouteSource.XIAOYI);
    }
    return { code: 0 };
  }

  private resolveRoute(intentName: string): string {
    if (intentName === XIAOYI_INTENT_START_PHOTO_REVIEW) {
      return LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT;
    }
    if (intentName === XIAOYI_INTENT_VIEW_PENDING_REVIEWS) {
      return LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING;
    }
    return '';
  }
}
