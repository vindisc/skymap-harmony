import promptAction from '@ohos.promptAction';

export enum ToastTone {
  SUCCESS = 'success',
  ERROR = 'error',
  WARNING = 'warning'
}

export class ToastService {
  static show(message: string, duration: number = 2200): void {
    promptAction.showToast({
      message,
      duration
    });
  }

  static success(message: string): void {
    ToastService.show(message);
  }

  static error(message: string): void {
    ToastService.show(message, 2800);
  }

  static warning(message: string): void {
    ToastService.show(message, 2600);
  }

  static byTone(message: string, tone: ToastTone): void {
    if (tone === ToastTone.ERROR) {
      ToastService.error(message);
      return;
    }
    if (tone === ToastTone.WARNING) {
      ToastService.warning(message);
      return;
    }
    ToastService.success(message);
  }
}
