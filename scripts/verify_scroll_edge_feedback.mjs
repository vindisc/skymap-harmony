import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const pagesDir = path.join(root, 'entry/src/main/ets/pages');
const componentPattern = /\b(Scroll|List|Swiper)\s*\(/;

let failed = false;

function collectEtsFiles(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...collectEtsFiles(fullPath));
      continue;
    }
    if (entry.isFile() && entry.name.endsWith('.ets')) {
      files.push(fullPath);
    }
  }
  return files;
}

function countToken(line, token) {
  let count = 0;
  for (const char of line) {
    if (char === token) {
      count += 1;
    }
  }
  return count;
}

function hasRequiredEdgeFeedback(lines, startIndex, componentName) {
  const requiredMarker = componentName === 'Swiper'
    ? '.effectMode(EdgeEffect.Spring)'
    : '.edgeEffect(EdgeEffect.Spring)';
  let depth = 0;
  let attributePhase = false;

  for (let index = startIndex; index < lines.length; index += 1) {
    const line = lines[index];
    const trimmed = line.trim();

    if (line.includes(requiredMarker)) {
      return true;
    }

    depth += countToken(line, '{') - countToken(line, '}');

    if (index > startIndex && depth <= 0) {
      attributePhase = true;
    }

    if (
      attributePhase &&
      index > startIndex &&
      trimmed.length > 0 &&
      !trimmed.startsWith('.') &&
      !trimmed.startsWith('}')
    ) {
      return false;
    }
  }

  return false;
}

for (const filePath of collectEtsFiles(pagesDir)) {
  const relativePath = path.relative(root, filePath);
  const lines = fs.readFileSync(filePath, 'utf8').split('\n');

  for (let index = 0; index < lines.length; index += 1) {
    const match = lines[index].match(componentPattern);
    if (!match) {
      continue;
    }

    const componentName = match[1];
    if (!hasRequiredEdgeFeedback(lines, index, componentName)) {
      failed = true;
      const expected = componentName === 'Swiper'
        ? '.effectMode(EdgeEffect.Spring)'
        : '.edgeEffect(EdgeEffect.Spring)';
      console.error(`${relativePath}:${index + 1} ${componentName} missing ${expected}`);
    }
  }
}

if (failed) {
  process.exit(1);
}

console.log('scroll edge feedback verified: Scroll/List use EdgeEffect.Spring and Swiper uses effectMode(EdgeEffect.Spring)');
