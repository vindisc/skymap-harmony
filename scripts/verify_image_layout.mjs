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
  { name: 'horizontal', width: 1600, height: 1000, expectedType: 'horizontal', expectedRatio: 1.6 },
  { name: 'vertical', width: 1152, height: 1536, expectedType: 'vertical', expectedRatio: 0.75 },
  { name: 'square', width: 1200, height: 1200, expectedType: 'square', expectedRatio: 1 },
  { name: 'fallback', width: 1600, height: 1000, fallbackUsed: true, expectedType: 'unknown', expectedRatio: 1 }
];

let failed = false;
for (const testCase of cases) {
  const result = resolveReviewImageLayout(testCase.width, testCase.height, testCase.fallbackUsed === true);
  const ratioMatches = Math.abs(result.aspectRatio - testCase.expectedRatio) < 0.0001;
  const typeMatches = result.layoutType === testCase.expectedType;
  if (!ratioMatches || !typeMatches) {
    failed = true;
    console.error(`${testCase.name}: expected ${testCase.expectedType}/${testCase.expectedRatio}, got ${result.layoutType}/${result.aspectRatio}`);
  } else {
    console.log(`${testCase.name}: ${result.layoutType}, aspectRatio=${result.aspectRatio}`);
  }
}

if (failed) {
  process.exit(1);
}
