import { UIContext } from '@ohos.arkui.UIContext';

export enum ToastTone {
  SUCCESS = 'success',
  ERROR = 'error',
  WARNING = 'warning'
}

export class ToastService {
  static show(uiContext: UIContext, message: string, duration: number = 2200): void {
    try {
      uiContext.getPromptAction().showToast({
        message,
        duration
      });
    } catch (error) {
      console.warn(`[ToastService] 展示提示失败：${error}`);
    }
  }

  static success(uiContext: UIContext, message: string): void {
    ToastService.show(uiContext, message);
  }

  static error(uiContext: UIContext, message: string): void {
    ToastService.show(uiContext, message, 2800);
  }

  static warning(uiContext: UIContext, message: string): void {
    ToastService.show(uiContext, message, 2600);
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
    ToastService.success(uiContext, message);
  }
}
