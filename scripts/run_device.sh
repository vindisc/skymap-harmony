#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

bash scripts/smoke_device.sh --check-only
bash scripts/build_hap.sh --signing debug
bash scripts/smoke_device.sh --launch
