#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HDC_DEFAULT="/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc"
HDC="${HDC:-$HDC_DEFAULT}"
BUNDLE_NAME="com.skymap.photoreview"
ABILITY_NAME="EntryAbility"
MODULE_NAME="entry"
SIGNED_HAP="$REPO_ROOT/entry/build/default/outputs/default/entry-default-signed.hap"
OUTPUT_DIR="$REPO_ROOT/test-artifacts/exif-device"
HILOG_FILE="$OUTPUT_DIR/hilog.txt"
RUN_BUILD=true
NORMAL_ENTRY_NEEDED=false

if [ "${1:-}" = "--skip-build" ]; then
  RUN_BUILD=false
elif [ "$#" -gt 0 ]; then
  echo "用法：bash scripts/test_exif_on_device.sh [--skip-build]" >&2
  exit 2
fi

cd "$REPO_ROOT"
mkdir -p "$OUTPUT_DIR"

restore_normal_entry() {
  if [ "$NORMAL_ENTRY_NEEDED" = false ]; then
    return 0
  fi
  "$HDC" shell aa start -a "$ABILITY_NAME" -b "$BUNDLE_NAME" -m "$MODULE_NAME" \
    --ps testScenario cleanup_test_data >/dev/null 2>&1 || true
  sleep 2
  "$HDC" shell aa force-stop "$BUNDLE_NAME" >/dev/null 2>&1 || true
  "$HDC" shell aa start -a "$ABILITY_NAME" -b "$BUNDLE_NAME" -m "$MODULE_NAME" >/dev/null
  NORMAL_ENTRY_NEEDED=false
  echo "已退出测试场景并恢复正常应用入口。"
}

cleanup_on_exit() {
  local status=$?
  trap - EXIT
  if ! restore_normal_entry && [ "$status" -eq 0 ]; then
    status=1
  fi
  exit "$status"
}

trap cleanup_on_exit EXIT

TARGETS="$($HDC list targets -v)"
if ! printf '%s\n' "$TARGETS" | awk '$3 == "Connected" { found=1 } END { exit found ? 0 : 1 }'; then
  echo "没有检测到 Connected 状态的鸿蒙设备。" >&2
  printf '%s\n' "$TARGETS" >&2
  exit 1
fi

node scripts/verify_exif_identity_recovery.mjs

if [ "$RUN_BUILD" = true ]; then
  SKYMAP_BUILD_JAVA_HOME="${SKYMAP_DEVICE_JAVA_HOME:-/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home}" \
    bash scripts/build_hap.sh --signing debug
fi

if [ ! -f "$SIGNED_HAP" ]; then
  echo "未找到签名 HAP：$SIGNED_HAP" >&2
  exit 1
fi

echo "覆盖安装当前 Debug HAP（保留应用数据）..."
"$HDC" install -r "$SIGNED_HAP"
NORMAL_ENTRY_NEEDED=true
"$HDC" shell hilog -r >/dev/null 2>&1 || true
"$HDC" shell aa force-stop "$BUNDLE_NAME" >/dev/null 2>&1 || true
"$HDC" shell aa start \
  -a "$ABILITY_NAME" \
  -b "$BUNDLE_NAME" \
  -m "$MODULE_NAME" \
  --ps testScenario canvas_spike_v2_l1_export

report_found=false
for _ in {1..20}; do
  sleep 1
  "$HDC" shell hilog -x > "$HILOG_FILE" 2>/dev/null || true
  if rg -q '\[CanvasSpikeV2L1Export\] \{' "$HILOG_FILE"; then
    report_found=true
    break
  fi
done

if [ "$report_found" = false ]; then
  echo "20 秒内未收到真机 EXIF 报告，日志：$HILOG_FILE" >&2
  exit 1
fi

node scripts/assert_exif_device_report.mjs "$HILOG_FILE"
echo "真机 EXIF 场景验证完成，日志：$HILOG_FILE"
