import {
  createDefaultReviewCardDocument,
  ReviewCardDocument,
  ReviewCardLayoutType,
  ReviewCardRenderMode
} from '../model/ReviewCardModel';
import { MobileReadingReviewCard } from './MobileReadingReviewCard';
import { LongFormExportReviewCard } from './LongFormExportReviewCard';

@Component
export struct ReviewCardRenderer {
  @Prop document: ReviewCardDocument = createDefaultReviewCardDocument();
  @Prop renderMode: ReviewCardRenderMode = ReviewCardRenderMode.MOBILE_READING;
  @Prop layoutType: ReviewCardLayoutType = ReviewCardLayoutType.HORIZONTAL;
  @Prop reviewerText: string = '';
  @Prop exportComponentId: string = '';
  @Prop exportCanvasHeight: number = 0;

  build() {
    // 阶段 A（B 方向）：L3（review_card / adaptive_review_card）走 renderMode 二分；
    // L0/L1/L2 尚未实现，兜底到同一路径（templateLevel 分支在 PR 4/5/8 补：
    //   if (level === TemplateLevel.L0_FRAME) L0Renderer(...)
    //   if (level === TemplateLevel.L1_META) L1Renderer(...)
    //   if (level === TemplateLevel.L2_NOTE) L2Renderer(...)
    // 见 mvp §10 PR 4 / PR 5 / PR 8。
    if (this.renderMode === ReviewCardRenderMode.MOBILE_READING) {
      MobileReadingReviewCard({
        document: this.document,
        layoutType: this.layoutType
      })
    } else {
      LongFormExportReviewCard({
        document: this.document,
        reviewerText: this.reviewerText,
        exportComponentId: this.exportComponentId,
        canvasHeight: this.exportCanvasHeight
      })
    }
  }
}
