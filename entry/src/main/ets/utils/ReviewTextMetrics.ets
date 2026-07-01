function estimateReviewTextRowUnits(row: string): number {
  let units: number = 0;
  for (let index: number = 0; index < row.length; index += 1) {
    const code: number = row.charCodeAt(index);
    if (code >= 0xD800 && code <= 0xDBFF && index + 1 < row.length) {
      units += 1.2;
      index += 1;
      continue;
    }

    if (code <= 0x007F) {
      units += 0.56;
      continue;
    }

    if (code >= 0xFF61 && code <= 0xFF9F) {
      units += 0.75;
      continue;
    }

    units += 1;
  }

  return units;
}

export function estimateReviewTextWrapUnitsPerLine(contentWidth: number, fontSize: number): number {
  const safeContentWidth: number = Math.max(120, contentWidth);
  const safeFontSize: number = Math.max(12, fontSize);
  // Reserve a little breathing room for real glyph width, caret space, and platform wrapping differences.
  return Math.max(8, (safeContentWidth / safeFontSize) * 0.8);
}

export function estimateReviewTextLineCount(value: string, defaultLines: number, wrapUnitsPerLine: number): number {
  if (value.length === 0) {
    return defaultLines;
  }

  const rows: Array<string> = value.split('\n');
  let lines: number = 0;
  const safeWrapUnits: number = Math.max(1, wrapUnitsPerLine);
  for (let index: number = 0; index < rows.length; index += 1) {
    const rowUnits: number = estimateReviewTextRowUnits(rows[index]);
    lines += Math.max(1, Math.ceil(rowUnits / safeWrapUnits));
  }

  return Math.max(defaultLines, lines);
}
