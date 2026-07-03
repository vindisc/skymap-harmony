import Want from '@ohos.app.ability.Want';
import {
  LEARNING_PROGRESS_WIDGET_ROUTE_HOME,
  LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING
} from './LearningProgressFormService';

const FORM_LAUNCH_TARGET_ROUTE_KEY: string = 'targetRoute';

export class FormLaunchIntentService {
  private static pendingRoute: string = '';

  static captureWant(want: Want | undefined): void {
    const routeValue: Object | undefined = want?.parameters?.[FORM_LAUNCH_TARGET_ROUTE_KEY];
    const route: string = `${routeValue ?? ''}`;
    if (route === LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING || route === LEARNING_PROGRESS_WIDGET_ROUTE_HOME) {
      FormLaunchIntentService.pendingRoute = route;
    }
  }

  static consumeRoute(): string {
    const route: string = FormLaunchIntentService.pendingRoute;
    FormLaunchIntentService.pendingRoute = '';
    return route;
  }
}
