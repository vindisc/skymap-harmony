import { ReviewCardStyleTokens } from './ReviewCardStyleTokens';
import { ReviewInfoItem } from './ReviewInfoItem';

@Component
export struct ReviewInfoGroup {
  @Prop firstLook: string = '';
  @Prop judgement: string = '';
  @Prop blocker: string = '';

  build() {
    Column() {
      ReviewInfoItem({
        label: '第一眼落点',
        value: this.firstLook,
        showDivider: false
      })
      ReviewInfoItem({
        label: '是否成立',
        value: this.judgement,
        showDivider: true
      })
      ReviewInfoItem({
        label: '卡点',
        value: this.blocker,
        showDivider: true
      })
    }
    .width('100%')
    .padding({
      top: 2,
      bottom: 0
    })
  }
}
