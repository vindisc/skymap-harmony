#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEVECO_APP_HOME="/Applications/DevEco-Studio.app/Contents"
HVIGOR_BIN="${DEVECO_APP_HOME}/tools/hvigor/bin/hvigorw"
RUN_BUILD=true
RUN_DEVICE=false
VERIFICATION_SUITE="smoke"
PROFILE_BACKUP=""

restore_profile() {
  if [ -n "$PROFILE_BACKUP" ] && [ -f "$PROFILE_BACKUP" ]; then
    cp "$PROFILE_BACKUP" build-profile.json5
    rm -f "$PROFILE_BACKUP"
    PROFILE_BACKUP=""
    echo "已恢复原 build-profile.json5。"
  fi
}

cleanup_on_exit() {
  local status=$?
  trap - EXIT
  restore_profile
  exit "$status"
}

trap cleanup_on_exit EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

usage() {
  cat <<'EOF'
用法：bash scripts/test_app.sh [--quick] [--all] [--device]

  默认       执行稳定冒烟校验并构建 Debug HAP
  --quick    仅执行校验脚本，不构建
  --all      执行全部发布门禁校验
  --device   在已连接设备上执行 Hypium 链路测试和 UI 截图矩阵
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --quick)
      RUN_BUILD=false
      shift
      ;;
    --device)
      RUN_DEVICE=true
      shift
      ;;
    --all)
      VERIFICATION_SUITE="all"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数：$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

cd "$REPO_ROOT"

if [ "$RUN_DEVICE" = true ]; then
  bash scripts/smoke_device.sh --check-only
fi

node scripts/run_verification_suite.mjs --suite "$VERIFICATION_SUITE"

if [ "$RUN_BUILD" = true ]; then
  export DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-${DEVECO_APP_HOME}/sdk}"
  export JAVA_HOME="${JAVA_HOME:-${DEVECO_APP_HOME}/jbr/Contents/Home}"
  export PATH="$JAVA_HOME/bin:$PATH"

  if [ ! -x "$HVIGOR_BIN" ]; then
    echo "未找到 hvigorw：$HVIGOR_BIN" >&2
    exit 1
  fi

  "$HVIGOR_BIN" --stop-daemon >/dev/null 2>&1 || true
  if [ "$RUN_DEVICE" = false ]; then
    PROFILE_BACKUP="$(mktemp "${TMPDIR:-/tmp}/skymap-test-build-profile.XXXXXX")"
    cp build-profile.json5 "$PROFILE_BACKUP"
    node scripts/manage_signing_profile.mjs deactivate
  fi
  "$HVIGOR_BIN" \
    --mode module \
    -p module=entry \
    -p product=default \
    -p buildMode=debug \
    assembleHap \
    --no-daemon
  restore_profile
fi

if [ "$RUN_DEVICE" = true ]; then
  "$HVIGOR_BIN" \
    --mode module \
    -p module=entry \
    -p product=default \
    -p buildMode=debug \
    onDeviceTest \
    --no-daemon
  bash scripts/smoke_device.sh
fi

echo "应用测试流程完成。"
