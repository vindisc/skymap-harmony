import Want from '@ohos.app.ability.Want';
import {
  FormLaunchIntentService,
  IntentRouteSource
} from './FormLaunchIntentService';
import {
  LEARNING_PROGRESS_WIDGET_ROUTE_HOME,
  LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING,
  LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT
} from './LearningProgressFormService';

const DEBUG_TEST_SCENARIO_KEY: string = 'testScenario';

export enum DebugTestScenario {
  HOME = 'home',
  PENDING = 'pending',
  TODAY = 'today'
}

export class DebugLaunchScenarioService {
  static captureWant(want: Want | undefined, isDebugBuild: boolean): void {
    if (!isDebugBuild) {
      return;
    }
    const scenarioValue: Object | undefined = want?.parameters?.[DEBUG_TEST_SCENARIO_KEY];
    const scenario: string = `${scenarioValue ?? ''}`;
    const route: string = DebugLaunchScenarioService.resolveRoute(scenario);
    if (route.length > 0) {
      FormLaunchIntentService.captureRouteFromIntent(route, IntentRouteSource.TEST);
    }
  }

  private static resolveRoute(scenario: string): string {
    if (scenario === DebugTestScenario.HOME) {
      return LEARNING_PROGRESS_WIDGET_ROUTE_HOME;
    }
    if (scenario === DebugTestScenario.PENDING) {
      return LEARNING_PROGRESS_WIDGET_ROUTE_LIBRARY_PENDING;
    }
    if (scenario === DebugTestScenario.TODAY) {
      return LEARNING_PROGRESS_WIDGET_ROUTE_TODAY_REVIEW_DIRECT;
    }
    return '';
  }
}
