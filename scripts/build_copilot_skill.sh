#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
references_dir="${repo_root}/skills/elixir-code-review/references"

render_reference() {
  local source_file="$1"
  local output_file="$2"

  awk '
    NR == 1 && $0 == "---" {
      in_frontmatter = 1
      next
    }
    in_frontmatter && $0 == "---" {
      in_frontmatter = 0
      next
    }
    !in_frontmatter {
      print
    }
  ' "${source_file}" > "${output_file}"
}

build_references() {
  local output_dir="$1"

  mkdir -p "${output_dir}"
  render_reference \
    "${repo_root}/agent/01_elixir_design_principles.md" \
    "${output_dir}/01_elixir_design_principles.md"

  local rule_file
  for rule_file in "${repo_root}"/agent/rules/*.md; do
    render_reference "${rule_file}" "${output_dir}/$(basename "${rule_file}")"
  done
}

if [[ "${1:-}" == "--check" ]]; then
  temporary_dir="$(mktemp -d)"
  trap 'rm -rf "${temporary_dir}"' EXIT
  build_references "${temporary_dir}/references"

  if ! diff -ru "${references_dir}" "${temporary_dir}/references"; then
    echo "Copilot skill references are stale. Run scripts/build_copilot_skill.sh." >&2
    exit 1
  fi

  echo "Copilot skill references are current."
  exit 0
fi

mkdir -p "${references_dir}"
find "${references_dir}" -maxdepth 1 -type f -name '*.md' -delete
build_references "${references_dir}"
echo "Generated Copilot skill references in ${references_dir}."
