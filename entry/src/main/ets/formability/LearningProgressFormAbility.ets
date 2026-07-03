import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';
import formInfo from '@ohos.app.form.formInfo';
import Want from '@ohos.app.ability.Want';
import { LearningProgressFormService } from '../services/LearningProgressFormService';

const FORM_IDENTITY_KEY: string = 'ohos.extra.param.key.form_identity';

function resolveFormId(want: Want): string {
  const formId: Object | undefined = want.parameters?.[FORM_IDENTITY_KEY];
  return `${formId ?? ''}`;
}

export default class LearningProgressFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId: string = resolveFormId(want);
    LearningProgressFormService.addFormId(this.context, formId)
      .then(() => LearningProgressFormService.refreshForm(this.context, formId))
      .catch((error: Error) => {
        console.error(`[LearningProgressFormAbility] 添加学习进度卡片失败：${error.message}`);
      });
    return LearningProgressFormService.createEmptyBindingData();
  }

  onUpdateForm(formId: string): void {
    LearningProgressFormService.refreshForm(this.context, formId).catch((error: Error) => {
      console.error(`[LearningProgressFormAbility] 更新学习进度卡片失败：${error.message}`);
    });
  }

  onRemoveForm(formId: string): void {
    LearningProgressFormService.removeFormId(this.context, formId).catch((error: Error) => {
      console.error(`[LearningProgressFormAbility] 移除学习进度卡片失败：${error.message}`);
    });
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}
