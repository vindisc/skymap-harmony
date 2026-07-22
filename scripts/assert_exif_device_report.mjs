import fs from 'node:fs';

const logPath = process.argv[2];
if (!logPath || !fs.existsSync(logPath)) {
  console.error('未找到真机 EXIF 日志。');
  process.exit(2);
}

const lines = fs.readFileSync(logPath, 'utf8').split(/\r?\n/);
let report = null;
for (const line of lines) {
  const marker = '[CanvasSpikeV2L1Export] ';
  const markerIndex = line.indexOf(marker);
  if (markerIndex < 0) continue;
  const jsonText = line.slice(markerIndex + marker.length).trim();
  try {
    report = JSON.parse(jsonText);
  } catch {
  }
}

if (report === null) {
  console.error('真机尚未生成 EXIF 验证报告。');
  process.exit(2);
}

const identity = report.exifIdentityVerification;
const cachedRepair = report.cachedIdentityRepairVerification;
if (!identity || identity.passed !== true || !cachedRepair ||
  cachedRepair.passed !== true || cachedRepair.exposurePreserved !== true || report.passed !== true) {
  console.error(`真机 EXIF 验证失败：${JSON.stringify(report)}`);
  process.exit(1);
}

console.log(
  `真机 EXIF 通过：相机品牌=${identity.cameraMake}，相机型号=${identity.cameraModel}，` +
  `镜头品牌=${identity.lensMake}，镜头型号=${identity.lensModel}；旧缓存补齐且曝光参数保持不变`
);
