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
LAYOUT_FILE="$OUTPUT_DIR/media-save-dialog.json"
REMOTE_LAYOUT_FILE="/data/local/tmp/skymap-exif-media-save-dialog.json"
PICKER_LAYOUT_FILE="$OUTPUT_DIR/photo-picker.json"
REMOTE_PICKER_LAYOUT_FILE="/data/local/tmp/skymap-exif-photo-picker.json"
RUN_BUILD=true
NORMAL_ENTRY_NEEDED=false
CREATED_MEDIA_URI=""
MEDIA_CLEANUP_COMPLETED=false
TEST_SCENARIO_STARTED=false

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

cleanup_test_media() {
  if [ "$TEST_SCENARIO_STARTED" = false ]; then
    return 0
  fi
  if [ "$MEDIA_CLEANUP_COMPLETED" = true ]; then
    return 0
  fi
  if [ -z "$CREATED_MEDIA_URI" ] && [ -f "$HILOG_FILE" ]; then
    CREATED_MEDIA_URI="$(node scripts/assert_exif_device_report.mjs "$HILOG_FILE" --media-uri 2>/dev/null || true)"
  fi
  if [[ "$CREATED_MEDIA_URI" == file://media/* ]] || [[ "$CREATED_MEDIA_URI" == datashare://media/* ]]; then
    if "$HDC" shell mediatool delete "$CREATED_MEDIA_URI" >/dev/null 2>&1; then
      echo "已删除真机回归创建的测试媒体资产。"
      CREATED_MEDIA_URI=""
      MEDIA_CLEANUP_COMPLETED=true
    else
      echo "测试媒体资产清理失败：$CREATED_MEDIA_URI" >&2
      return 1
    fi
  fi
}

cleanup_on_exit() {
  local status=$?
  trap - EXIT
  if ! cleanup_test_media && [ "$status" -eq 0 ]; then
    status=1
  fi
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
TEST_SCENARIO_STARTED=true

dialog_confirmed=false
for _ in {1..15}; do
  sleep 1
  "$HDC" shell uitest dumpLayout -p "$REMOTE_LAYOUT_FILE" >/dev/null 2>&1 || true
  "$HDC" file recv "$REMOTE_LAYOUT_FILE" "$LAYOUT_FILE" >/dev/null 2>&1 || true
  BUTTON_COORDINATES="$(node scripts/find_ui_confirmation_button.mjs "$LAYOUT_FILE" 2>/dev/null || true)"
  if [ -n "$BUTTON_COORDINATES" ]; then
    read -r BUTTON_X BUTTON_Y BUTTON_TEXT <<< "$BUTTON_COORDINATES"
    echo "自动确认系统相册对话框：$BUTTON_TEXT"
    "$HDC" shell uitest uiInput click "$BUTTON_X" "$BUTTON_Y" >/dev/null
    dialog_confirmed=true
    break
  fi
done

if [ "$dialog_confirmed" = false ]; then
  echo "15 秒内未找到系统相册确认按钮。" >&2
  exit 1
fi

picker_confirmed=false
for _ in {1..20}; do
  sleep 1
  "$HDC" shell uitest dumpLayout -i -p "$REMOTE_PICKER_LAYOUT_FILE" >/dev/null 2>&1 || true
  "$HDC" file recv "$REMOTE_PICKER_LAYOUT_FILE" "$PICKER_LAYOUT_FILE" >/dev/null 2>&1 || true
  BUTTON_COORDINATES="$(node scripts/find_ui_confirmation_button.mjs "$PICKER_LAYOUT_FILE" --first-photo 2>/dev/null || true)"
  if [ -n "$BUTTON_COORDINATES" ]; then
    read -r BUTTON_X BUTTON_Y BUTTON_TEXT <<< "$BUTTON_COORDINATES"
    echo "自动选择相册中刚创建的受控测试照片：$BUTTON_TEXT"
    "$HDC" shell uitest uiInput click "$BUTTON_X" "$BUTTON_Y" >/dev/null
    picker_confirmed=true
    break
  fi
done

if [ "$picker_confirmed" = false ]; then
  echo "20 秒内未找到系统照片选择器中的最新受控测试照片。" >&2
  exit 1
fi

for _ in {1..5}; do
  sleep 1
  "$HDC" shell uitest dumpLayout -i -p "$REMOTE_PICKER_LAYOUT_FILE" >/dev/null 2>&1 || true
  "$HDC" file recv "$REMOTE_PICKER_LAYOUT_FILE" "$PICKER_LAYOUT_FILE" >/dev/null 2>&1 || true
  COMPLETE_COORDINATES="$(node scripts/find_ui_confirmation_button.mjs "$PICKER_LAYOUT_FILE" --complete 2>/dev/null || true)"
  if [ -n "$COMPLETE_COORDINATES" ]; then
    read -r COMPLETE_X COMPLETE_Y COMPLETE_TEXT <<< "$COMPLETE_COORDINATES"
    echo "自动确认受控测试照片预览：$COMPLETE_TEXT"
    "$HDC" shell uitest uiInput click "$COMPLETE_X" "$COMPLETE_Y" >/dev/null
    break
  fi
done

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
CREATED_MEDIA_URI="$(node scripts/assert_exif_device_report.mjs "$HILOG_FILE" --media-uri)"
cleanup_test_media
echo "真机 EXIF 场景验证完成，日志：$HILOG_FILE"
