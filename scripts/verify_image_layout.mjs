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
  { name: 'vertical', width: 1152, height: 1536, expectedType: 'vertical', expectedRatio: 0.75, expectedStructure: 'left-image-right-text' },
  { name: 'square', width: 1200, height: 1200, expectedType: 'square', expectedRatio: 1, expectedStructure: 'top-image-bottom-text' },
  { name: 'fallback', width: 1600, height: 1000, fallbackUsed: true, expectedType: 'unknown', expectedRatio: 1, expectedStructure: 'top-image-bottom-text' }
];

function resolveReviewCardStructure(layoutType) {
  if (layoutType === 'vertical') {
    return 'left-image-right-text';
  }
  return 'top-image-bottom-text';
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

if (failed) {
  process.exit(1);
}
