import { UIContext } from '@ohos.arkui.UIContext';
import { ToastDurationTokens } from '../theme/DesignTokens';

export enum ToastTone {
  SUCCESS = 'success',
  INFO = 'info',
  WARNING = 'warning',
  ERROR = 'error'
}

export class ToastService {
  static success(uiContext: UIContext, message: string): void {
    ToastService._showRaw(uiContext, message, ToastDurationTokens.success);
  }

  static info(uiContext: UIContext, message: string): void {
    ToastService._showRaw(uiContext, message, ToastDurationTokens.info);
  }

  static warning(uiContext: UIContext, message: string): void {
    ToastService._showRaw(uiContext, message, ToastDurationTokens.warning);
  }

  static error(uiContext: UIContext, message: string): void {
    ToastService._showRaw(uiContext, message, ToastDurationTokens.error);
  }

  static byTone(uiContext: UIContext, message: string, tone: ToastTone): void {
    if (tone === ToastTone.ERROR) {
      ToastService.error(uiContext, message);
      return;
    }
    if (tone === ToastTone.WARNING) {
      ToastService.warning(uiContext, message);
      return;
    }
    if (tone === ToastTone.INFO) {
      ToastService.info(uiContext, message);
      return;
    }
    ToastService.success(uiContext, message);
  }

  private static _showRaw(uiContext: UIContext, message: string, duration: number): void {
    try {
      uiContext.getPromptAction().showToast({
        message,
        duration
      });
    } catch (error) {
      console.warn(`[ToastService] 展示提示失败：${error}`);
    }
  }
}
