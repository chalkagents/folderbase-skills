#!/usr/bin/env bash
set -euo pipefail

test_directory=$(
  CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
  pwd
)
repository_root=$(
  CDPATH= cd -- "$test_directory/.." >/dev/null 2>&1
  pwd
)
temporary_root=$(mktemp -d)
trap 'rm -R "$temporary_root"' EXIT

export DISABLE_TELEMETRY=1
skills_cli="$repository_root/node_modules/.bin/skills"
test -x "$skills_cli"

list_output=$(
  "$skills_cli" add "$repository_root" --list
)
if ! grep -Fq 'work-with-folderbase' <<<"$list_output"; then
  printf '%s\n' 'The Skills CLI did not discover work-with-folderbase.' >&2
  exit 1
fi

verify_install() {
  local agent=$1
  local install_directory=$2
  local project_root="$temporary_root/$agent"
  local installed_skill="$project_root/$install_directory/work-with-folderbase"

  mkdir -p "$project_root"
  git -C "$project_root" init --quiet
  (
    cd "$project_root"
    "$skills_cli" add \
      "$repository_root" \
      --agent "$agent" \
      --skill work-with-folderbase \
      --copy \
      --yes
  )

  cmp \
    "$repository_root/skills/work-with-folderbase/SKILL.md" \
    "$installed_skill/SKILL.md"
  cmp \
    "$repository_root/skills/work-with-folderbase/references/protocol-surface.md" \
    "$installed_skill/references/protocol-surface.md"
  test -f "$project_root/skills-lock.json"
}

verify_install codex .agents/skills
verify_install claude-code .claude/skills

printf '%s\n' 'Folderbase skill discovery and isolated installs are valid.'
