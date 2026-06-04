import router from '@ohos.router';
import { EDITOR_PAGE } from '../app/AppRouter';
import { ReviewCardStore } from '../services/ReviewCardStore';
import { SampleImageKind } from '../utils/ImageLayoutUtils';

@Entry
@Component
struct HomePage {
  private startDraft(kind: SampleImageKind): void {
    ReviewCardStore.createDraft(kind);
    router.pushUrl({ url: EDITOR_PAGE });
  }

  @Builder
  SampleButton(label: string, kind: SampleImageKind) {
    Button(label)
      .height(44)
      .width('100%')
      .borderRadius(6)
      .fontSize(15)
      .onClick(() => {
        this.startDraft(kind);
      })
  }

  build() {
    Column() {
      Column() {
        Text('摄影复盘卡')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2329')
          .width('100%')
        Text('选择一张照片，写下你的观察，生成一张复盘卡')
          .fontSize(15)
          .fontColor('#68707D')
          .lineHeight(22)
          .margin({ top: 10 })
          .width('100%')

        Column({ space: 10 }) {
          this.SampleButton('新建复盘：示例横图', 'horizontal')
          this.SampleButton('新建复盘：示例竖图', 'vertical')
          this.SampleButton('新建复盘：示例方图', 'square')
        }
        .width('100%')
        .margin({ top: 28 })

        Column() {
          Text('最近记录')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F2329')
            .width('100%')
          Text('第一版暂不保存历史，后续会在这里展示草稿和导出记录。')
            .fontSize(14)
            .fontColor('#68707D')
            .lineHeight(21)
            .margin({ top: 10 })
            .width('100%')
        }
        .padding(16)
        .width('100%')
        .borderRadius(8)
        .backgroundColor('#FFFFFF')
        .margin({ top: 28 })
      }
      .padding(24)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7F9')
  }
}

