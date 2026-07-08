#!/usr/bin/env bash

set -euo pipefail

DEVECO_APP_HOME="/Applications/DevEco-Studio.app/Contents"
DEVECO_SDK_HOME_DEFAULT="${DEVECO_APP_HOME}/sdk"
DEVECO_JAVA_HOME_DEFAULT="${DEVECO_APP_HOME}/jbr/Contents/Home"
HVIGOR_BIN="${DEVECO_APP_HOME}/tools/hvigor/bin/hvigorw"

export DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-$DEVECO_SDK_HOME_DEFAULT}"
export JAVA_HOME="${JAVA_HOME:-$DEVECO_JAVA_HOME_DEFAULT}"
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

exec "$HVIGOR_BIN" \
  --mode module \
  -p module=entry \
  -p product=default \
  assembleHap \
  --no-daemon
