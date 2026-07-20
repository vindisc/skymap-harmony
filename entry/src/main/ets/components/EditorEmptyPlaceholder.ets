import { PickedPhotoResult, pickSinglePhoto } from '../services/PhotoPickerService';
import { AppColors, AppMetrics, AppTypography } from './AppDesign';

@Component
export struct EditorEmptyPlaceholder {
  onPicked: (result: PickedPhotoResult) => void = () => {};
  @State isPicking: boolean = false;

  private async pickPhoto(): Promise<void> {
    if (this.isPicking) {
      return;
    }
    this.isPicking = true;
    try {
      const result: PickedPhotoResult = await pickSinglePhoto();
      this.onPicked(result);
    } finally {
      this.isPicking = false;
    }
  }

  build() {
    Column({ space: AppMetrics.space16 }) {
      Column({ space: AppMetrics.space8 }) {
        Text('▧')
          .fontFamily('NotoSansSC-Regular')
          .fontSize(AppTypography.pageTitle)
          .fontColor(AppColors.placeholderText)

        Text('先选一张照片，再开始排版')
          .fontFamily('NotoSansSC-Regular')
          .fontSize(AppTypography.body)
          .fontColor(AppColors.secondaryText)
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height(148)
      .borderRadius(AppMetrics.cardRadius)
      .backgroundColor(AppColors.surfaceTint)
      .border({ width: 1, color: AppColors.border })

      Button(this.isPicking ? '正在打开相册…' : '从相册选一张')
        .fontFamily('NotoSansSC-Bold')
        .fontSize(AppTypography.buttonText)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.onPrimary)
        .height(AppMetrics.controlHeight)
        .padding({ left: AppMetrics.space24, right: AppMetrics.space24 })
        .borderRadius(AppMetrics.buttonRadius)
        .backgroundColor(this.isPicking ? AppColors.primaryDisabled : AppColors.primary)
        .enabled(!this.isPicking)
        .onClick(() => {
          this.pickPhoto();
        })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .padding(AppMetrics.cardPadding)
  }
}
