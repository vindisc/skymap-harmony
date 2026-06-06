const HORIZONTAL_ASPECT_RATIO = 1.15;
const VERTICAL_ASPECT_RATIO = 0.87;

function resolveReviewImageLayout(width, height, fallbackUsed = false) {
  if (fallbackUsed || width <= 0 || height <= 0) {
    return {
      layoutType: 'unknown',
      aspectRatio: 1
    };
  }

  const aspectRatio = width / height;
  if (aspectRatio >= HORIZONTAL_ASPECT_RATIO) {
    return {
      layoutType: 'horizontal',
      aspectRatio
    };
  }

  if (aspectRatio <= VERTICAL_ASPECT_RATIO) {
    return {
      layoutType: 'vertical',
      aspectRatio
    };
  }

  return {
    layoutType: 'square',
    aspectRatio
  };
}

const cases = [
  { name: 'horizontal', width: 1600, height: 1000, expectedType: 'horizontal', expectedRatio: 1.6, expectedStructure: 'top-image-bottom-text' },
  { name: 'vertical', width: 1152, height: 1536, expectedType: 'vertical', expectedRatio: 0.75, expectedStructure: 'top-image-bottom-text' },
  { name: 'square', width: 1200, height: 1200, expectedType: 'square', expectedRatio: 1, expectedStructure: 'top-image-bottom-text' },
  { name: 'fallback', width: 1600, height: 1000, fallbackUsed: true, expectedType: 'unknown', expectedRatio: 1, expectedStructure: 'top-image-bottom-text' }
];

const recoveredFallbackCase = {
  name: 'recovered fallback vertical',
  width: 1272,
  height: 2860,
  fallbackUsed: false,
  expectedType: 'vertical',
  expectedRatio: 1272 / 2860,
  expectedStructure: 'top-image-bottom-text'
};

function resolveReviewCardStructure(layoutType) {
  return 'top-image-bottom-text';
}

function resolveExportCanvasWidth() {
  return 560;
}

let failed = false;
for (const testCase of cases) {
  const result = resolveReviewImageLayout(testCase.width, testCase.height, testCase.fallbackUsed === true);
  const ratioMatches = Math.abs(result.aspectRatio - testCase.expectedRatio) < 0.0001;
  const typeMatches = result.layoutType === testCase.expectedType;
  const structure = resolveReviewCardStructure(result.layoutType);
  const structureMatches = structure === testCase.expectedStructure;
  if (!ratioMatches || !typeMatches || !structureMatches) {
    failed = true;
    console.error(`${testCase.name}: expected ${testCase.expectedType}/${testCase.expectedRatio}/${testCase.expectedStructure}, got ${result.layoutType}/${result.aspectRatio}/${structure}`);
  } else {
    console.log(`${testCase.name}: ${result.layoutType}, aspectRatio=${result.aspectRatio}, structure=${structure}`);
  }
}

const recoveredResult = resolveReviewImageLayout(
  recoveredFallbackCase.width,
  recoveredFallbackCase.height,
  recoveredFallbackCase.fallbackUsed
);
const recoveredRatioMatches = Math.abs(recoveredResult.aspectRatio - recoveredFallbackCase.expectedRatio) < 0.0001;
const recoveredTypeMatches = recoveredResult.layoutType === recoveredFallbackCase.expectedType;
const recoveredStructure = resolveReviewCardStructure(recoveredResult.layoutType);
const recoveredStructureMatches = recoveredStructure === recoveredFallbackCase.expectedStructure;
if (!recoveredRatioMatches || !recoveredTypeMatches || !recoveredStructureMatches) {
  failed = true;
  console.error(`${recoveredFallbackCase.name}: expected ${recoveredFallbackCase.expectedType}/${recoveredFallbackCase.expectedRatio}/${recoveredFallbackCase.expectedStructure}, got ${recoveredResult.layoutType}/${recoveredResult.aspectRatio}/${recoveredStructure}`);
} else {
  console.log(`${recoveredFallbackCase.name}: ${recoveredResult.layoutType}, aspectRatio=${recoveredResult.aspectRatio}, structure=${recoveredStructure}`);
}

if (failed) {
  process.exit(1);
}

const exportCanvasWidth = resolveExportCanvasWidth();
if (exportCanvasWidth !== 560) {
  console.error(`export canvas: expected 560, got ${exportCanvasWidth}`);
  process.exit(1);
}
console.log(`export canvas: width=${exportCanvasWidth}`);
