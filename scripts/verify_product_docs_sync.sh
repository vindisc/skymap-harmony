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
require_file "docs/review-library-v1.md"
require_file "docs/mobile-main-flow.md"
require_file "docs/product/FEATURE_MATRIX.md"
require_file "docs/product/ROADMAP.md"
require_file "docs/product/REVIEW_LIBRARY_V0_AUDIT.md"
require_file "docs/product/REVIEW_LIBRARY_V1_ACCEPTANCE.md"

require_text "docs/review-library-v0.md" "ReviewExchangeJSON"
require_text "docs/review-library-v0.md" "reviewerText"
require_text "docs/review-library-v0.md" "旧历史记录"
require_text "docs/review-library-v0.md" "不删除原照片"
require_text "docs/review-library-v0.md" "Review Library v1 轻量体验增强"

require_text "docs/review-library-v1.md" "移动端复盘查看入口"
require_text "docs/review-library-v1.md" "复盘人为空时不显示脏占位"
require_text "docs/review-library-v1.md" "创建第一条复盘"
require_text "docs/review-library-v1.md" '不修改 `review.json` 字段'

require_text "docs/mobile-main-flow.md" "复盘库"
require_text "docs/mobile-main-flow.md" "旧记录缺少复盘人"
require_text "docs/mobile-main-flow.md" "列表卡片优先展示标题、是否成立、核心关系和当前卡点"
require_text "docs/mobile-main-flow.md" "左滑删除只删除本地历史记录"

require_text "docs/product/FEATURE_MATRIX.md" "Review Library"
require_text "docs/product/FEATURE_MATRIX.md" "v1 轻量体验增强"
require_text "docs/product/FEATURE_MATRIX.md" "Mac 支持本地照片状态、缩略图和 Finder 定位"
require_text "docs/product/FEATURE_MATRIX.md" "Harmony 支持移动端复盘库浏览"
require_text "docs/product/FEATURE_MATRIX.md" '本轮不改 `review.json` 字段'

require_text "docs/product/ROADMAP.md" "Review Library v1 轻量体验增强"
require_text "docs/product/ROADMAP.md" "已推进"
require_text "docs/product/ROADMAP.md" "标签、收藏、批注"
require_text "docs/product/ROADMAP.md" "不进入本轮"

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

require_text "docs/product/REVIEW_LIBRARY_V1_ACCEPTANCE.md" "localPhotoPath"
require_text "docs/product/REVIEW_LIBRARY_V1_ACCEPTANCE.md" "不把缩略图写入跨端协议"
require_text "docs/product/REVIEW_LIBRARY_V1_ACCEPTANCE.md" "Finder 定位只影响 Mac 本地"
require_text "docs/product/REVIEW_LIBRARY_V1_ACCEPTANCE.md" '不会自动覆盖原始 `review.json`'
require_text "docs/product/REVIEW_LIBRARY_V1_ACCEPTANCE.md" "复盘人为空时不显示复盘人文本"
require_text "docs/product/REVIEW_LIBRARY_V1_ACCEPTANCE.md" "不新增标签、收藏、批注、成长统计或 AI 分析"

SIBLING_AUDIT="$ROOT/../skymap-mac/docs/product/REVIEW_LIBRARY_V0_AUDIT.md"
if [ -f "$SIBLING_AUDIT" ]; then
  cmp -s "$ROOT/docs/product/REVIEW_LIBRARY_V0_AUDIT.md" "$SIBLING_AUDIT" \
    || fail "Mac and Harmony audit docs are not identical"
fi

SIBLING_MATRIX="$ROOT/../skymap-mac/docs/product/FEATURE_MATRIX.md"
if [ -f "$SIBLING_MATRIX" ]; then
  cmp -s "$ROOT/docs/product/FEATURE_MATRIX.md" "$SIBLING_MATRIX" \
    || fail "Mac and Harmony feature matrix docs are not identical"
fi

SIBLING_ROADMAP="$ROOT/../skymap-mac/docs/product/ROADMAP.md"
if [ -f "$SIBLING_ROADMAP" ]; then
  cmp -s "$ROOT/docs/product/ROADMAP.md" "$SIBLING_ROADMAP" \
    || fail "Mac and Harmony roadmap docs are not identical"
fi

SIBLING_V1_ACCEPTANCE="$ROOT/../skymap-mac/docs/product/REVIEW_LIBRARY_V1_ACCEPTANCE.md"
if [ -f "$SIBLING_V1_ACCEPTANCE" ]; then
  cmp -s "$ROOT/docs/product/REVIEW_LIBRARY_V1_ACCEPTANCE.md" "$SIBLING_V1_ACCEPTANCE" \
    || fail "Mac and Harmony v1 acceptance docs are not identical"
fi

echo "product docs sync: ok"
