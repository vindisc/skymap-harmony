import { UIContext } from '@ohos.arkui.UIContext';
import { AppColors } from '../components/AppDesign';

export enum DialogTone {
  PRIMARY = 'primary',
  DANGER = 'danger',
  WARNING = 'warning'
}

interface ConfirmDialogOptions {
  title: string;
  message: string;
  cancelText: string;
  confirmText: string;
  tone?: DialogTone;
  onConfirm: () => void;
}

interface AlertDialogOptions {
  title: string;
  message: string;
  okText: string;
  tone?: DialogTone;
  onDismiss?: () => void;
}

function resolveConfirmColor(tone: DialogTone): string {
  if (tone === DialogTone.DANGER) {
    return AppColors.danger;
  }
  if (tone === DialogTone.WARNING) {
    return AppColors.tagAmberText;
  }
  return AppColors.primary;
}

export class DialogService {
  static confirm(uiContext: UIContext, options: ConfirmDialogOptions): void {
    const tone: DialogTone = options.tone ?? DialogTone.PRIMARY;
    uiContext.getPromptAction().showDialog({
      title: options.title,
      message: options.message,
      buttons: [
        {
          text: options.cancelText,
          color: AppColors.secondaryText
        },
        {
          text: options.confirmText,
          color: resolveConfirmColor(tone)
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

  static alert(uiContext: UIContext, options: AlertDialogOptions): void {
    const tone: DialogTone = options.tone ?? DialogTone.PRIMARY;
    uiContext.getPromptAction().showDialog({
      title: options.title,
      message: options.message,
      buttons: [
        {
          text: options.okText,
          color: resolveConfirmColor(tone)
        }
      ]
    }).then(() => {
      if (options.onDismiss) {
        options.onDismiss();
      }
    }).catch((error: Error) => {
      console.warn(`[DialogService] 展示告知弹窗失败：${error.message}`);
    });
  }
}
