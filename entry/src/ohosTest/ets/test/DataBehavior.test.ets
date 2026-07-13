import common from '@ohos.app.ability.common';
import { abilityDelegatorRegistry } from '@kit.TestKit';
import { describe, expect, it } from '@ohos/hypium';
import {
  createDefaultReviewCardDocument,
  getReviewDocumentKey,
  ReviewCardDocument,
  ReviewCardHistoryItem,
  ReviewJudgementStatus
} from '../../../main/ets/model/ReviewCardModel';
import { PendingReviewPhotoStatus } from '../../../main/ets/model/PendingReviewPhotoModel';
import { PendingReviewPhotoStore } from '../../../main/ets/services/PendingReviewPhotoStore';
import { ReviewCardRdbService } from '../../../main/ets/services/ReviewCardRdbService';
import {
  createReviewLibraryBackupEnvelope,
  parseReviewLibraryBackupEnvelope,
  ReviewLibraryBackupEnvelopeV1,
  ReviewLibraryBackupPayloadV1
} from '../../../main/ets/services/ReviewLibraryBackupService';
import {
  ReviewBundleManifestV2,
  validateReviewBundleV2Texts
} from '../../../main/ets/services/ReviewBundleOriginalPhotoExportService';

const FIXTURE_TIME: number = 1783987200000;

function getTestContext(): common.UIAbilityContext {
  return abilityDelegatorRegistry.getAbilityDelegator().getAppContext() as common.UIAbilityContext;
}

function createTestDocument(uniqueTime: number = FIXTURE_TIME): ReviewCardDocument {
  const document: ReviewCardDocument = createDefaultReviewCardDocument();
  document.createdAt = uniqueTime;
  document.updatedAt = uniqueTime + 1000;
  document.imageUri = 'test://behavior/photo.jpg';
  document.imageWidth = 1600;
  document.imageHeight = 1000;
  document.content.title = '行为测试复盘';
  document.content.judgement = ReviewJudgementStatus.VALID;
  return document;
}

export default function dataBehaviorTest(): void {
  describe('DataBehaviorTest', (): void => {
    it('importsMarksAndDeletesPendingPhoto', 0, async (): Promise<void> => {
      const context: common.UIAbilityContext = getTestContext();
      const uri: string = `test://pending/${Date.now()}.jpg`;
      let photoId: string = '';
      try {
        const photo = await PendingReviewPhotoStore.addPhoto(context, uri, 1200, 1800);
        photoId = photo.id;
        expect(photo.photoUri).assertEqual(uri);
        expect(photo.status).assertEqual(PendingReviewPhotoStatus.PENDING);
        expect(photo.orientation).assertEqual('vertical');

        await PendingReviewPhotoStore.markReviewed(context, photoId, 'behavior_review');
        const reviewed = await PendingReviewPhotoStore.getById(context, photoId);
        expect(reviewed !== undefined).assertTrue();
        expect(reviewed?.status).assertEqual(PendingReviewPhotoStatus.REVIEWED);
        expect(reviewed?.linkedReviewId).assertEqual('behavior_review');
      } finally {
        if (photoId.length > 0) {
          await PendingReviewPhotoStore.delete(context, photoId);
        }
      }
      expect(await PendingReviewPhotoStore.getById(context, photoId)).assertUndefined();
    });

    it('savesUpdatesAndDeletesReview', 0, async (): Promise<void> => {
      const context: common.UIAbilityContext = getTestContext();
      const uniqueTime: number = Date.now();
      const reviewId: string = `behavior_review_${uniqueTime}`;
      const document: ReviewCardDocument = createTestDocument(uniqueTime);
      try {
        await ReviewCardRdbService.upsertReview(context, { document: document, exportedPath: '' }, reviewId);
        const saved = await ReviewCardRdbService.getReview(context, reviewId);
        expect(saved !== undefined).assertTrue();
        expect(saved?.document.content.title).assertEqual('行为测试复盘');

        const updated: ReviewCardHistoryItem = { document: document, exportedPath: '/behavior/export.png' };
        await ReviewCardRdbService.upsertReview(context, updated, reviewId);
        expect((await ReviewCardRdbService.getReview(context, reviewId))?.exportedPath)
          .assertEqual('/behavior/export.png');
      } finally {
        await ReviewCardRdbService.deleteReview(context, reviewId);
      }
      expect(await ReviewCardRdbService.getReview(context, reviewId)).assertUndefined();
    });

    it('roundTripsBackupAndRejectsTampering', 0, (): void => {
      const document: ReviewCardDocument = createTestDocument();
      const payload: ReviewLibraryBackupPayloadV1 = {
        createdAt: FIXTURE_TIME,
        appVersion: '0.1.0',
        reviewCount: 1,
        reviews: [{
          reviewId: getReviewDocumentKey(document),
          document: document,
          exportedPath: '/behavior/export.png'
        }],
        settings: {
          reviewerName: '测试复盘人',
          widgetCardBackgroundStyle: 'plain',
          shatterAnimationEnabled: true
        }
      };
      const envelope: ReviewLibraryBackupEnvelopeV1 = createReviewLibraryBackupEnvelope(payload);
      const restored: ReviewLibraryBackupEnvelopeV1 =
        parseReviewLibraryBackupEnvelope(JSON.stringify(envelope));
      expect(restored.payload.createdAt).assertEqual(FIXTURE_TIME);
      expect(restored.payload.reviews[0].document.content.title).assertEqual('行为测试复盘');

      envelope.payload.reviews[0].document.content.title = '被篡改';
      let rejected: boolean = false;
      try {
        parseReviewLibraryBackupEnvelope(JSON.stringify(envelope));
      } catch (error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });

    it('validatesBundleContractAndRejectsPollutedReviewJson', 0, (): void => {
      const originalPath: string = 'assets/original/photo.jpg';
      const manifest: ReviewBundleManifestV2 = {
        bundleVersion: 2,
        bundleType: 'original-photo-review',
        bundleId: 'behavior_bundle',
        createdAt: '2026-07-14T00:00:00.000Z',
        updatedAt: '2026-07-14T00:00:00.000Z',
        sourceApp: 'skymap-photoreview',
        sourceAppVersion: '0.1.0',
        platform: 'HarmonyOS',
        reviewJsonPath: 'review.json',
        exportedImages: [],
        originalPhoto: {
          included: true,
          path: originalPath,
          fileName: 'photo.jpg',
          mimeType: 'image/jpeg',
          pixelWidth: 1600,
          pixelHeight: 1000,
          fileSize: 1024
        },
        review: {
          decision: 'works',
          titleText: '行为测试',
          reviewTimeText: '2026-07-14',
          reviewerText: '测试复盘人'
        }
      };
      validateReviewBundleV2Texts(JSON.stringify(manifest), '{"titleText":"行为测试"}', originalPath);

      let rejected: boolean = false;
      try {
        validateReviewBundleV2Texts(
          JSON.stringify(manifest),
          '{"titleText":"行为测试","bundleId":"不应出现"}',
          originalPath
        );
      } catch (error) {
        rejected = true;
      }
      expect(rejected).assertTrue();
    });
  });
}
