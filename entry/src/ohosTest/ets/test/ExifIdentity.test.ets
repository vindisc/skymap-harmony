import { describe, expect, it } from '@ohos/hypium';
import { ExifPayload, ExifSource } from '../../../main/ets/model/ExifPayloadModel';
import {
  hasMissingExifIdentity,
  inferCameraMake,
  inferLensMake,
  mergeMissingExifIdentity
} from '../../../main/ets/services/ExifReaderService';

function createPayload(): ExifPayload {
  return {
    cameraMake: '',
    cameraModel: '',
    lensMake: '',
    lensModel: '',
    focalLength: '',
    aperture: '',
    shutter: '',
    iso: '',
    captureDate: '',
    location: '',
    source: ExifSource.AUTO,
    manuallyOverridden: []
  };
}

export default function exifIdentityTest(): void {
  describe('ExifIdentityTest', (): void => {
    it('infersKnownSonyAndTamronIdentity', 0, (): void => {
      expect(inferCameraMake('ILCE-7CM2')).assertEqual('SONY');
      expect(inferLensMake('E 28-200mm F2.8-5.6 A071')).assertEqual('TAMRON');
      expect(inferLensMake('Unknown 50mm F1.8')).assertEqual('');
    });

    it('repairsPartialCachedExifWithoutLosingExposureData', 0, (): void => {
      const cached: ExifPayload = createPayload();
      cached.lensModel = 'E 28-200mm F2.8-5.6 A071';
      cached.focalLength = '74mm';
      cached.aperture = 'f/5.6';
      cached.shutter = '1/1250';
      cached.iso = 'ISO160';

      const automatic: ExifPayload = createPayload();
      automatic.cameraMake = 'SONY';
      automatic.cameraModel = 'ILCE-7CM2';
      automatic.lensMake = 'TAMRON';
      automatic.lensModel = 'E 28-200mm F2.8-5.6 A071';

      expect(hasMissingExifIdentity(cached)).assertTrue();
      const repaired: ExifPayload = mergeMissingExifIdentity(cached, automatic);
      expect(repaired.cameraMake).assertEqual('SONY');
      expect(repaired.cameraModel).assertEqual('ILCE-7CM2');
      expect(repaired.lensMake).assertEqual('TAMRON');
      expect(repaired.lensModel).assertEqual('E 28-200mm F2.8-5.6 A071');
      expect(repaired.focalLength).assertEqual('74mm');
      expect(repaired.aperture).assertEqual('f/5.6');
      expect(repaired.shutter).assertEqual('1/1250');
      expect(repaired.iso).assertEqual('ISO160');
      expect(hasMissingExifIdentity(repaired)).assertFalse();
    });

    it('preservesIntentionallyClearedManualIdentity', 0, (): void => {
      const cached: ExifPayload = createPayload();
      cached.cameraMake = '';
      cached.cameraModel = 'ILCE-7CM2';
      cached.lensModel = 'E 28-200mm F2.8-5.6 A071';
      cached.manuallyOverridden = ['cameraMake'];
      cached.source = ExifSource.MIXED;

      const automatic: ExifPayload = createPayload();
      automatic.cameraMake = 'SONY';
      automatic.cameraModel = 'ILCE-7CM2';
      automatic.lensMake = 'TAMRON';

      const repaired: ExifPayload = mergeMissingExifIdentity(cached, automatic);
      expect(repaired.cameraMake).assertEqual('');
      expect(repaired.cameraModel).assertEqual('ILCE-7CM2');
      expect(repaired.lensMake).assertEqual('TAMRON');
      expect(repaired.source).assertEqual(ExifSource.MIXED);
      expect(hasMissingExifIdentity(repaired)).assertFalse();
    });
  });
}
