#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
current_docs="${repo_root}/docs/product"

if [[ ! -d "${current_docs}" ]]; then
  echo "Missing current Product Layer directory: ${current_docs}" >&2
  exit 1
fi

other_docs="${SKymap_PRODUCT_DOCS_OTHER_PATH:-${SKYMAP_PRODUCT_DOCS_OTHER_PATH:-}}"
other_repo="${SKymap_OTHER_REPO_PATH:-${SKYMAP_OTHER_REPO_PATH:-}}"

if [[ -n "${other_docs}" && -n "${other_repo}" ]]; then
  echo "Set only one of SKymap_PRODUCT_DOCS_OTHER_PATH or SKymap_OTHER_REPO_PATH." >&2
  exit 1
fi

if [[ -n "${other_repo}" ]]; then
  other_docs="${other_repo%/}/docs/product"
fi

if [[ -z "${other_docs}" ]]; then
  parent_dir="$(dirname "${repo_root}")"
  grandparent_dir="$(dirname "${parent_dir}")"
  repo_name="$(basename "${repo_root}")"

  candidates=()
  case "${repo_name}" in
    *mac*|*Mac*)
      candidates+=(
        "${parent_dir}/skymap-HarmonyOS/docs/product"
        "${parent_dir}/skymap-harmony/docs/product"
        "${parent_dir}/skymap-harmony-product-docs/docs/product"
        "${grandparent_dir}/skymap-HarmonyOS/docs/product"
        "${grandparent_dir}/skymap-harmony/docs/product"
        "${grandparent_dir}/worktrees/skymap-harmony-product-docs/docs/product"
      )
      ;;
    *Harmony*|*harmony*)
      candidates+=(
        "${parent_dir}/skymap-mac/docs/product"
        "${parent_dir}/skymap-mac-product-docs/docs/product"
        "${grandparent_dir}/skymap-mac/docs/product"
        "${grandparent_dir}/worktrees/skymap-mac-product-docs/docs/product"
      )
      ;;
  esac

  for candidate in "${candidates[@]}"; do
    if [[ -d "${candidate}" ]]; then
      other_docs="${candidate}"
      break
    fi
  done
fi

if [[ -z "${other_docs}" || ! -d "${other_docs}" ]]; then
  cat >&2 <<'EOF'
Unable to locate the other Product Layer directory.

Set one of:
  SKymap_OTHER_REPO_PATH=/path/to/other/repo
  SKymap_PRODUCT_DOCS_OTHER_PATH=/path/to/other/repo/docs/product
EOF
  exit 1
fi

echo "Comparing Product Layer directories:"
echo "  current: ${current_docs}"
echo "  other:   ${other_docs}"

diff -ru -x '.DS_Store' "${current_docs}" "${other_docs}"

echo "Product Layer docs are in sync."
