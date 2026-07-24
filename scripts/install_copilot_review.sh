#!/usr/bin/env bash

set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "Usage: scripts/install_copilot_review.sh /path/to/elixir/repository" >&2
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
target_repo="$(cd "$1" && pwd)"

if [[ ! -d "${target_repo}/.git" ]]; then
  echo "Target is not a Git repository: ${target_repo}" >&2
  exit 1
fi

"${script_dir}/validate_copilot_skill.sh"

skill_target="${target_repo}/.github/skills/elixir-code-review"
if [[ -e "${skill_target}" ]]; then
  echo "Refusing to overwrite existing skill: ${skill_target}" >&2
  exit 1
fi

mkdir -p "${target_repo}/.github/skills"
cp -R "${repo_root}/skills/elixir-code-review" "${target_repo}/.github/skills/"

instructions_target="${target_repo}/.github/copilot-instructions.md"
path_instructions_target="${target_repo}/.github/instructions/elixir.instructions.md"

if [[ -e "${instructions_target}" ]]; then
  echo "Kept existing ${instructions_target}; merge copilot/templates/copilot-instructions.md manually."
else
  cp "${repo_root}/copilot/templates/copilot-instructions.md" "${instructions_target}"
fi

mkdir -p "$(dirname "${path_instructions_target}")"
if [[ -e "${path_instructions_target}" ]]; then
  echo "Kept existing ${path_instructions_target}; merge the template manually."
else
  cp "${repo_root}/copilot/templates/elixir.instructions.md" "${path_instructions_target}"
fi

echo "Installed Elixir Copilot review configuration in ${target_repo}."
echo "Review and commit the files under ${target_repo}/.github."
