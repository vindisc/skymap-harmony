import Want from '@ohos.app.ability.Want';
import {
  LEARNING_PROGRESS_WIDGET_ROUTE_HOME,
  LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING,
  LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT
} from './LearningProgressFormService';

const FORM_LAUNCH_TARGET_ROUTE_KEY: string = 'targetRoute';

type FormLaunchIntentListener = () => void;

export enum IntentRouteSource {
  FORM = 'form',
  XIAOYI = 'xiaoyi',
  TEST = 'test'
}

export class FormLaunchIntentService {
  private static pendingRoute: string = '';
  private static listeners: Array<FormLaunchIntentListener> = [];

  static captureWant(want: Want | undefined): void {
    const routeValue: Object | undefined = want?.parameters?.[FORM_LAUNCH_TARGET_ROUTE_KEY];
    const route: string = `${routeValue ?? ''}`;
    FormLaunchIntentService.captureRoute(route, IntentRouteSource.FORM);
  }

  static captureRouteFromIntent(route: string, source: IntentRouteSource): void {
    FormLaunchIntentService.captureRoute(route, source);
  }

  static consumeRoute(): string {
    const route: string = FormLaunchIntentService.pendingRoute;
    FormLaunchIntentService.pendingRoute = '';
    return route;
  }

  static subscribe(listener: FormLaunchIntentListener): void {
    if (FormLaunchIntentService.listeners.indexOf(listener) < 0) {
      FormLaunchIntentService.listeners.push(listener);
    }
  }

  static unsubscribe(listener: FormLaunchIntentListener): void {
    FormLaunchIntentService.listeners = FormLaunchIntentService.listeners.filter((
      item: FormLaunchIntentListener
    ): boolean => item !== listener);
  }

  private static notifyListeners(): void {
    FormLaunchIntentService.listeners.forEach((listener: FormLaunchIntentListener): void => {
      listener();
    });
  }

  private static captureRoute(route: string, source: IntentRouteSource): void {
    if (source !== IntentRouteSource.FORM &&
      source !== IntentRouteSource.XIAOYI &&
      source !== IntentRouteSource.TEST) {
      return;
    }
    if (route !== LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING &&
      route !== LEARNING_PROGRESS_WIDGET_ROUTE_HOME &&
      route !== LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT) {
      return;
    }
    FormLaunchIntentService.pendingRoute = route;
    console.info(`[FormLaunchIntentService] captured route from ${source}`);
    FormLaunchIntentService.notifyListeners();
  }
}
