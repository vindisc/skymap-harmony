import fs from 'node:fs';

const logPath = process.argv[2];
if (!logPath || !fs.existsSync(logPath)) {
  console.error('未找到真机 EXIF 日志。');
  process.exit(2);
}

const lines = fs.readFileSync(logPath, 'utf8').split(/\r?\n/);
let report = null;
let createdMediaUri = '';
for (const line of lines) {
  const mediaMarker = '[ExifDeviceTestMedia] created=';
  const mediaMarkerIndex = line.indexOf(mediaMarker);
  if (mediaMarkerIndex >= 0) {
    createdMediaUri = line.slice(mediaMarkerIndex + mediaMarker.length).trim();
  }
  const marker = '[CanvasSpikeV2L1Export] ';
  const markerIndex = line.indexOf(marker);
  if (markerIndex < 0) continue;
  const jsonText = line.slice(markerIndex + marker.length).trim();
  try {
    report = JSON.parse(jsonText);
  } catch {
  }
}

if (process.argv.includes('--media-uri')) {
  const mediaUri = report?.mediaUriIdentityVerification?.mediaUri || createdMediaUri;
  if (mediaUri) {
    process.stdout.write(mediaUri);
    process.exit(0);
  }
  process.exit(2);
}

if (report === null) {
  console.error('真机尚未生成 EXIF 验证报告。');
  process.exit(2);
}

const identity = report.exifIdentityVerification;
const cachedRepair = report.cachedIdentityRepairVerification;
const mediaIdentity = report.mediaUriIdentityVerification;

if (!identity || identity.passed !== true || !cachedRepair ||
  cachedRepair.passed !== true || cachedRepair.exposurePreserved !== true ||
  !mediaIdentity || mediaIdentity.passed !== true || !mediaIdentity.mediaUri || report.passed !== true) {
  console.error(`真机 EXIF 验证失败：${JSON.stringify(report)}`);
  process.exit(1);
}

console.log(
  `真机 EXIF 通过：相机品牌=${identity.cameraMake}，相机型号=${identity.cameraModel}，` +
  `镜头品牌=${identity.lensMake}，镜头型号=${identity.lensModel}；` +
  `真实媒体 URI 通过，旧缓存补齐且曝光参数保持不变`
);
