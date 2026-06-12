#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() {
  echo "product docs sync: $*" >&2
  exit 1
}

require_file() {
  local path="$1"
  [ -f "$ROOT/$path" ] || fail "missing $path"
}

require_text() {
  local path="$1"
  local text="$2"
  grep -Fq "$text" "$ROOT/$path" || fail "$path missing text: $text"
}

require_file "docs/review-library-v0.md"
require_file "docs/mobile-main-flow.md"
require_file "docs/product/REVIEW_LIBRARY_V0_AUDIT.md"

require_text "docs/review-library-v0.md" "ReviewExchangeJSON"
require_text "docs/review-library-v0.md" "reviewerText"
require_text "docs/review-library-v0.md" "旧历史记录"
require_text "docs/review-library-v0.md" "不删除原照片"

require_text "docs/mobile-main-flow.md" "复盘库"
require_text "docs/mobile-main-flow.md" "旧记录缺少复盘人"
require_text "docs/mobile-main-flow.md" "左滑删除只删除本地历史记录"

require_text "docs/product/REVIEW_LIBRARY_V0_AUDIT.md" "不新增标签、收藏、批注"
require_text "docs/product/REVIEW_LIBRARY_V0_AUDIT.md" "ReviewLibraryItem"
require_text "docs/product/REVIEW_LIBRARY_V0_AUDIT.md" "ReviewLibraryStore"
require_text "docs/product/REVIEW_LIBRARY_V0_AUDIT.md" "ReviewLibrarySheet"
require_text "docs/product/REVIEW_LIBRARY_V0_AUDIT.md" "AppModel"
require_text "docs/product/REVIEW_LIBRARY_V0_AUDIT.md" "ReviewLibraryService"
require_text "docs/product/REVIEW_LIBRARY_V0_AUDIT.md" "ReviewCardHistoryService"
require_text "docs/product/REVIEW_LIBRARY_V0_AUDIT.md" "旧 Harmony 历史记录没有"
require_text "docs/product/REVIEW_LIBRARY_V0_AUDIT.md" "载入当前照片"
require_text "docs/product/REVIEW_LIBRARY_V0_AUDIT.md" "不删除原照片"

SIBLING_AUDIT="$ROOT/../skymap-mac/docs/product/REVIEW_LIBRARY_V0_AUDIT.md"
if [ -f "$SIBLING_AUDIT" ]; then
  cmp -s "$ROOT/docs/product/REVIEW_LIBRARY_V0_AUDIT.md" "$SIBLING_AUDIT" \
    || fail "Mac and Harmony audit docs are not identical"
fi

echo "product docs sync: ok"
