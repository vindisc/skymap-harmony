#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEVECO_APP_HOME="/Applications/DevEco-Studio.app/Contents"
DEVECO_SDK_HOME_DEFAULT="${DEVECO_APP_HOME}/sdk"
DEVECO_JAVA_HOME_DEFAULT="${DEVECO_APP_HOME}/jbr/Contents/Home"
SIGNING_JAVA_HOME_DEFAULT="/Library/Java/JavaVirtualMachines/zulu-11.jdk/Contents/Home"
HVIGOR_BIN="${DEVECO_APP_HOME}/tools/hvigor/bin/hvigorw"
SIGNING_MODE="${SKYMAP_SIGNING_MODE:-unsigned}"
SHOW_STATUS=false

usage() {
  cat <<'EOF'
用法：bash scripts/build_hap.sh [--signing unsigned|debug|release] [--status]

  --signing unsigned  使用仓库净化配置构建，不加载本机签名（默认）
  --signing debug     临时加载 build-profile.local.json5 的 debug/default 签名
  --signing release   临时加载 build-profile.local.json5 的 release 签名
  --status            只显示仓库签名状态和本机可用模式
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --signing)
      if [ "$#" -lt 2 ]; then
        usage >&2
        exit 2
      fi
      SIGNING_MODE="$2"
      shift 2
      ;;
    --status)
      SHOW_STATUS=true
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

if [[ ! "$SIGNING_MODE" =~ ^(unsigned|debug|release)$ ]]; then
  echo "不支持的签名模式：$SIGNING_MODE" >&2
  usage >&2
  exit 2
fi

cd "$REPO_ROOT"

if [ "$SHOW_STATUS" = true ]; then
  node scripts/manage_signing_profile.mjs status
  exit 0
fi

node scripts/manage_signing_profile.mjs assert-safe

PROFILE_BACKUP="$(mktemp "${TMPDIR:-/tmp}/skymap-build-profile.XXXXXX")"
cp build-profile.json5 "$PROFILE_BACKUP"

restore_profile() {
  if [ -n "$PROFILE_BACKUP" ] && [ -f "$PROFILE_BACKUP" ]; then
    cp "$PROFILE_BACKUP" build-profile.json5
    node scripts/manage_signing_profile.mjs refresh-status
    rm -f "$PROFILE_BACKUP"
    PROFILE_BACKUP=""
    echo "已恢复仓库 build-profile.json5。"
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

if [ "$SIGNING_MODE" != "unsigned" ]; then
  node scripts/manage_signing_profile.mjs activate "$SIGNING_MODE"
else
  node scripts/manage_signing_profile.mjs deactivate
fi

if [ "$SIGNING_MODE" = "release" ]; then
  BUILD_MODE="release"
else
  BUILD_MODE="debug"
fi

echo "构建模式：${BUILD_MODE}；签名模式：${SIGNING_MODE}"

export DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-$DEVECO_SDK_HOME_DEFAULT}"
if [ "$SIGNING_MODE" != "unsigned" ] && [ -x "$SIGNING_JAVA_HOME_DEFAULT/bin/java" ]; then
  JAVA_HOME_DEFAULT="${SKYMAP_BUILD_JAVA_HOME:-$SIGNING_JAVA_HOME_DEFAULT}"
else
  JAVA_HOME_DEFAULT="${SKYMAP_BUILD_JAVA_HOME:-${JAVA_HOME:-$DEVECO_JAVA_HOME_DEFAULT}}"
fi
export JAVA_HOME="$JAVA_HOME_DEFAULT"
export PATH="$JAVA_HOME/bin:$PATH"

if [ ! -d "$DEVECO_SDK_HOME" ]; then
  echo "DEVECO_SDK_HOME 无效：$DEVECO_SDK_HOME" >&2
  echo "请确认 DevEco Studio 已安装，或先显式设置正确的 DEVECO_SDK_HOME。" >&2
  exit 1
fi

if [ ! -x "$HVIGOR_BIN" ]; then
  echo "未找到 hvigorw：$HVIGOR_BIN" >&2
  exit 1
fi

if [ ! -x "$JAVA_HOME/bin/java" ]; then
  echo "JAVA_HOME 无效：$JAVA_HOME" >&2
  echo "请确认 DevEco Studio 自带 JBR 存在，或先显式设置正确的 JAVA_HOME。" >&2
  exit 1
fi

# 避免 DevEco Studio 中遗留的 daemon 继续复用错误 SDK 环境。
"$HVIGOR_BIN" --stop-daemon >/dev/null 2>&1 || true

"$HVIGOR_BIN" \
  --mode module \
  -p module=entry \
  -p product=default \
  -p buildMode="$BUILD_MODE" \
  assembleHap \
  --no-daemon
