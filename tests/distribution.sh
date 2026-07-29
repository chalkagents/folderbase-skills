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
published_source=${FOLDERBASE_SKILLS_PUBLISHED_SOURCE:-https://github.com/chalkagents/folderbase-skills/tree/v0.2.1}
published_ref=${FOLDERBASE_SKILLS_PUBLISHED_REF:-v0.2.1}
published_hash=${FOLDERBASE_SKILLS_PUBLISHED_HASH:-d829f6f4a218b8771e11f42de905ab2b24e15707a05e16dfb180414ba8749fde}
published_skill_sha=${FOLDERBASE_SKILLS_SKILL_SHA:-6127734f977c9b2bf983043e1f30666ab920efc7f732943bab630fa923d29a97}
published_reference_sha=${FOLDERBASE_SKILLS_REFERENCE_SHA:-a41b2bc5d83dad6df2a2a3ceca0618980b9f54db4063a82d0133c5239c7b2821}
test -x "$skills_cli"

local_list_output=$(
  "$skills_cli" add "$repository_root" --list
)
if ! grep -Fq 'work-with-folderbase' <<<"$local_list_output"; then
  printf '%s\n' 'The Skills CLI did not discover the local work-with-folderbase skill.' >&2
  exit 1
fi

published_list_output=$(
  "$skills_cli" add "$published_source" --list
)
if ! grep -Fq 'work-with-folderbase' <<<"$published_list_output"; then
  printf '%s\n' 'The Skills CLI did not discover the published work-with-folderbase skill.' >&2
  exit 1
fi

install_skill() {
  local source=$1
  local agent=$2
  local project_root=$3

  mkdir -p "$project_root"
  git -C "$project_root" init --quiet
  (
    cd "$project_root"
    "$skills_cli" add \
      "$source" \
      --agent "$agent" \
      --skill work-with-folderbase \
      --copy \
      --yes
  )
}

verify_local_install() {
  local agent=$1
  local install_directory=$2
  local project_root="$temporary_root/local-$agent"
  local installed_skill="$project_root/$install_directory/work-with-folderbase"

  install_skill "$repository_root" "$agent" "$project_root"

  cmp \
    "$repository_root/skills/work-with-folderbase/SKILL.md" \
    "$installed_skill/SKILL.md"
  cmp \
    "$repository_root/skills/work-with-folderbase/references/protocol-surface.md" \
    "$installed_skill/references/protocol-surface.md"
  test -f "$project_root/skills-lock.json"
}

verify_published_install() {
  local agent=$1
  local install_directory=$2
  local project_root="$temporary_root/published-$agent"
  local installed_skill="$project_root/$install_directory/work-with-folderbase"

  install_skill "$published_source" "$agent" "$project_root"

  test -f "$installed_skill/SKILL.md"
  test -f "$installed_skill/references/protocol-surface.md"
  test -f "$project_root/skills-lock.json"
  python3 - \
    "$project_root/skills-lock.json" \
    "$published_ref" \
    "$published_hash" <<'PY'
import json
import sys

lock = json.load(open(sys.argv[1], encoding="utf-8"))
skill = lock["skills"]["work-with-folderbase"]
assert skill["source"] == "chalkagents/folderbase-skills"
assert skill["ref"] == sys.argv[2]
assert skill["sourceType"] == "github"
assert skill["skillPath"] == "skills/work-with-folderbase/SKILL.md"
assert skill["computedHash"] == sys.argv[3]
PY
  test "$(
    shasum -a 256 "$installed_skill/SKILL.md" |
      awk '{ print $1 }'
  )" = "$published_skill_sha"
  test "$(
    shasum -a 256 "$installed_skill/references/protocol-surface.md" |
      awk '{ print $1 }'
  )" = "$published_reference_sha"
}

verify_local_install codex .agents/skills
verify_local_install claude-code .claude/skills
verify_local_install cursor .agents/skills
verify_local_install hermes-agent .hermes/skills
verify_local_install openclaw skills
verify_published_install codex .agents/skills
verify_published_install claude-code .claude/skills
verify_published_install cursor .agents/skills
verify_published_install hermes-agent .hermes/skills
verify_published_install openclaw skills

printf '%s\n' \
  'Local and version-pinned published Folderbase skill installs are valid.'
