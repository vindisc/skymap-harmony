import { UIContext } from '@ohos.arkui.UIContext';

interface ConfirmDialogOptions {
  title: string;
  message: string;
  cancelText: string;
  confirmText: string;
  confirmColor?: string;
  onConfirm: () => void;
}

export class DialogService {
  static confirm(uiContext: UIContext, options: ConfirmDialogOptions): void {
    uiContext.getPromptAction().showDialog({
      title: options.title,
      message: options.message,
      buttons: [
        {
          text: options.cancelText,
          color: '#666666'
        },
        {
          text: options.confirmText,
          color: options.confirmColor ?? '#0A84FF'
        }
      ]
    }).then((result) => {
      if (result.index === 1) {
        options.onConfirm();
      }
    }).catch((error: Error) => {
      console.warn(`[DialogService] 展示确认弹窗失败：${error.message}`);
    });
  }
}
