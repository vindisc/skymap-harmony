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
CHECK_ONLY=false
RESTORE_APP=false
LAUNCH_APP=false
NORMAL_APP_RESTORE_NEEDED=false
SCENARIOS=(
  home
  pending
  today
  editor_horizontal
  editor_vertical
  editor_square
  preview_horizontal
  preview_vertical
  preview_square
  preview_long_text
  reviewer_profile
  home_hero_settings
  widget_card_settings
  home_storage
  review_settings
  sync_center
)

if [ "${1:-}" = "--check-only" ]; then
  CHECK_ONLY=true
elif [ "${1:-}" = "--restore-app" ]; then
  RESTORE_APP=true
elif [ "${1:-}" = "--launch" ]; then
  LAUNCH_APP=true
elif [ "$#" -gt 0 ]; then
  echo "未知参数：$1" >&2
  exit 2
fi

if [ ! -x "$HDC" ]; then
  echo "未找到 hdc：$HDC" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

TARGET_FILE="$(mktemp "${TMPDIR:-/tmp}/skymap-hdc-targets.XXXXXX")"
"$HDC" list targets -v > "$TARGET_FILE" 2>/dev/null &
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
TARGETS_VERBOSE="$(sed -e '/^$/d' -e '/^\[Empty\]$/d' "$TARGET_FILE")"
rm -f "$TARGET_FILE"
TARGET_COUNT="$(printf '%s\n' "$TARGETS_VERBOSE" | sed '/^$/d' | wc -l | tr -d ' ')"
if [ "$TARGET_COUNT" -eq 0 ]; then
  echo "没有检测到 HarmonyOS 设备。请先连接真机或启动模拟器。" >&2
  exit 1
fi
if [ -n "${SKYMAP_HDC_TARGET:-}" ]; then
  SELECTED_TARGET_STATE="$(printf '%s\n' "$TARGETS_VERBOSE" | awk -v target="$SKYMAP_HDC_TARGET" '$1 == target { print $3; exit }')"
  if [ "$SELECTED_TARGET_STATE" != "Connected" ]; then
    echo "指定设备不可用：$SKYMAP_HDC_TARGET（状态：${SELECTED_TARGET_STATE:-未找到}）。" >&2
    printf '%s\n' "$TARGETS_VERBOSE" >&2
    exit 1
  fi
else
  ONLINE_TARGETS="$(printf '%s\n' "$TARGETS_VERBOSE" | awk '$3 == "Connected" { print $1 }')"
  ONLINE_TARGET_COUNT="$(printf '%s\n' "$ONLINE_TARGETS" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [ "$ONLINE_TARGET_COUNT" -eq 0 ]; then
    echo "检测到 HarmonyOS 设备，但当前不是 Connected 状态：" >&2
    printf '%s\n' "$TARGETS_VERBOSE" >&2
    echo "请解锁设备，确认 USB 调试授权并重新插拔数据线后重试。" >&2
    exit 1
  fi
  if [ "$ONLINE_TARGET_COUNT" -gt 1 ]; then
    echo "检测到多个在线设备，请设置 SKYMAP_HDC_TARGET 后重试：" >&2
    printf '%s\n' "$TARGETS_VERBOSE" >&2
    exit 1
  fi
fi

if [ -n "${SKYMAP_HDC_TARGET:-}" ]; then
  HDC_COMMAND=("$HDC" -t "$SKYMAP_HDC_TARGET")
else
  HDC_COMMAND=("$HDC")
fi

if [ "$CHECK_ONLY" = true ]; then
  echo "HarmonyOS 测试设备已连接。"
  exit 0
fi

if [ "$RESTORE_APP" = true ] && [ "${SKYMAP_ALLOW_DATA_RESET:-}" != "1" ]; then
  echo "已阻止卸载应用：恢复完整应用会清空当前应用数据。" >&2
  exit 2
fi

if [ ! -f "$SIGNED_HAP" ]; then
  echo "未找到可安装的 Debug 签名包：$SIGNED_HAP" >&2
  echo "请先配置本机 debug 签名并构建。" >&2
  exit 1
fi

if [ "$LAUNCH_APP" = true ]; then
  echo "覆盖安装 Debug 签名 HAP..."
  "${HDC_COMMAND[@]}" install -r "$SIGNED_HAP"
  "${HDC_COMMAND[@]}" shell aa force-stop "$BUNDLE_NAME" >/dev/null 2>&1 || true
  "${HDC_COMMAND[@]}" shell aa start \
    -a "$ABILITY_NAME" \
    -b "$BUNDLE_NAME" \
    -m "$MODULE_NAME"
  echo "应用已安装并启动，原有应用数据已保留。"
  exit 0
fi

if [ "$RESTORE_APP" = true ]; then
  echo "卸载测试应用..."
  "${HDC_COMMAND[@]}" uninstall "$BUNDLE_NAME"
  echo "安装完整 Debug HAP..."
  "${HDC_COMMAND[@]}" install -r "$SIGNED_HAP"
  LAUNCH_OUTPUT="$("${HDC_COMMAND[@]}" shell aa start \
    -a "$ABILITY_NAME" \
    -b "$BUNDLE_NAME" \
    -m "$MODULE_NAME" 2>&1)"
  printf '%s\n' "$LAUNCH_OUTPUT"
  case "$LAUNCH_OUTPUT" in
    *"failed to start ability"*)
      echo "完整应用已安装；设备仍处于锁屏状态，请解锁后手动启动。"
      ;;
    *)
      echo "完整应用已安装并启动。"
      ;;
  esac
  exit 0
fi

restore_normal_app() {
  if [ "$NORMAL_APP_RESTORE_NEEDED" = false ]; then
    return 0
  fi

  echo "正在退出测试场景并恢复正常应用入口..."
  "${HDC_COMMAND[@]}" shell aa force-stop "$BUNDLE_NAME" >/dev/null 2>&1 || true
  if "${HDC_COMMAND[@]}" shell aa start \
    -a "$ABILITY_NAME" \
    -b "$BUNDLE_NAME" \
    -m "$MODULE_NAME"; then
    NORMAL_APP_RESTORE_NEEDED=false
    echo "已恢复正常应用入口，真机可直接继续使用。"
    return 0
  fi

  echo "正常应用入口恢复失败，请保持设备在线后执行：bash scripts/smoke_device.sh --launch" >&2
  return 1
}

cleanup_on_exit() {
  local status=$?
  trap - EXIT
  if ! restore_normal_app && [ "$status" -eq 0 ]; then
    status=1
  fi
  exit "$status"
}

echo "安装 Debug HAP..."
"${HDC_COMMAND[@]}" install -r "$SIGNED_HAP"
NORMAL_APP_RESTORE_NEEDED=true
trap cleanup_on_exit EXIT

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

for scenario in "${SCENARIOS[@]}"; do
  launch_scenario "$scenario"
done

"${HDC_COMMAND[@]}" shell hilog -x > "$OUTPUT_DIR/hilog.txt" 2>/dev/null || true

REPORT_PATH="$OUTPUT_DIR/report.md"
{
  echo "# 见遇 UI 冒烟截图"
  echo
  echo "生成时间：$(date '+%Y-%m-%d %H:%M:%S')"
  echo
  for scenario in "${SCENARIOS[@]}"; do
    echo "## $scenario"
    echo
    if [ -s "$OUTPUT_DIR/${scenario}.jpeg" ]; then
      echo "![${scenario}](./${scenario}.jpeg)"
    else
      echo "截图缺失"
    fi
    echo
  done
} > "$REPORT_PATH"

restore_normal_app
echo "设备冒烟完成，产物目录：$OUTPUT_DIR"
