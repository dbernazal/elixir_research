#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

"${script_dir}/build_copilot_skill.sh" --check
ruby "${script_dir}/validate_copilot_skill.rb"

if [[ "${1:-}" == "--github" ]]; then
  if command -v gh >/dev/null 2>&1 && gh skill --help >/dev/null 2>&1; then
    gh skill publish "${repo_root}" --dry-run
  else
    echo "Cannot run GitHub validation because 'gh skill' is unavailable." >&2
    exit 1
  fi
fi
