#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HDC_DEFAULT="/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc"
HDC="${HDC:-$HDC_DEFAULT}"
BUNDLE_NAME="com.skymap.photoreview"
ABILITY_NAME="EntryAbility"
MODULE_NAME="entry"
OUTPUT_DIR="$REPO_ROOT/test-artifacts/device-smoke"
SIGNED_HAP="$REPO_ROOT/entry/build/default/outputs/default/entry-default-signed.hap"

if [ ! -x "$HDC" ]; then
  echo "未找到 hdc：$HDC" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

TARGET_FILE="$(mktemp "${TMPDIR:-/tmp}/skymap-hdc-targets.XXXXXX")"
"$HDC" list targets > "$TARGET_FILE" 2>/dev/null &
HDC_LIST_PID=$!
for _ in {1..32}; do
  if ! kill -0 "$HDC_LIST_PID" 2>/dev/null; then
    break
  fi
  sleep 0.25
done
if kill -0 "$HDC_LIST_PID" 2>/dev/null; then
  kill "$HDC_LIST_PID" 2>/dev/null || true
  wait "$HDC_LIST_PID" 2>/dev/null || true
  rm -f "$TARGET_FILE"
  echo "hdc 查询设备超时。请检查 USB 调试、设备授权或模拟器状态。" >&2
  exit 1
fi
wait "$HDC_LIST_PID" 2>/dev/null || true
TARGETS="$(sed -e '/^$/d' -e '/^\[Empty\]$/d' "$TARGET_FILE")"
rm -f "$TARGET_FILE"
TARGET_COUNT="$(printf '%s\n' "$TARGETS" | sed '/^$/d' | wc -l | tr -d ' ')"
if [ "$TARGET_COUNT" -eq 0 ]; then
  echo "没有检测到 HarmonyOS 设备。请先连接真机或启动模拟器。" >&2
  exit 1
fi
if [ "$TARGET_COUNT" -gt 1 ] && [ -z "${SKYMAP_HDC_TARGET:-}" ]; then
  echo "检测到多个设备，请设置 SKYMAP_HDC_TARGET 后重试：" >&2
  printf '%s\n' "$TARGETS" >&2
  exit 1
fi

if [ -n "${SKYMAP_HDC_TARGET:-}" ]; then
  HDC_COMMAND=("$HDC" -t "$SKYMAP_HDC_TARGET")
else
  HDC_COMMAND=("$HDC")
fi

if [ ! -f "$SIGNED_HAP" ]; then
  echo "未找到可安装的 Debug 签名包：$SIGNED_HAP" >&2
  echo "请先配置本机 debug 签名并构建。" >&2
  exit 1
fi

echo "安装 Debug HAP..."
"${HDC_COMMAND[@]}" install -r "$SIGNED_HAP"

launch_scenario() {
  local scenario="$1"
  echo "启动测试场景：$scenario"
  "${HDC_COMMAND[@]}" shell aa start \
    -a "$ABILITY_NAME" \
    -b "$BUNDLE_NAME" \
    -m "$MODULE_NAME" \
    --ps testScenario "$scenario"
  sleep 2

  local remote_image="/data/local/tmp/skymap-${scenario}.jpeg"
  if "${HDC_COMMAND[@]}" shell snapshot_display -f "$remote_image" >/dev/null 2>&1; then
    "${HDC_COMMAND[@]}" file recv "$remote_image" "$OUTPUT_DIR/${scenario}.jpeg" >/dev/null
  fi
}

launch_scenario home
launch_scenario pending
launch_scenario today

"${HDC_COMMAND[@]}" shell hilog -x > "$OUTPUT_DIR/hilog.txt" 2>/dev/null || true
echo "设备冒烟完成，产物目录：$OUTPUT_DIR"
