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
published_source=${FOLDERBASE_SKILLS_PUBLISHED_SOURCE:-https://github.com/chalkagents/folderbase-skills/tree/v0.3.0}
published_ref=${FOLDERBASE_SKILLS_PUBLISHED_REF:-v0.3.0}
published_hash=${FOLDERBASE_SKILLS_PUBLISHED_HASH:-0e3e8035100107c6dc1ff7aeb0fb968c058b7f9d7654f781323b0381b63b3e0f}
published_skill_sha=${FOLDERBASE_SKILLS_SKILL_SHA:-35718d726a76346fd1177636caaa6a61af9a6d20aa8cdf55a0273e05656a34ae}
published_reference_sha=${FOLDERBASE_SKILLS_REFERENCE_SHA:-7aa27908fe0da69a1da0a7795de046227a186b519cc3c0b269be416202396f6c}
catalog_source=${FOLDERBASE_SKILLS_CATALOG_SOURCE:-chalkagents/folderbase-skills}
test -x "$skills_cli"
test "$("$skills_cli" --version)" = "1.5.20"

verify_discovery() {
  local source=$1
  local description=$2
  local discovery_output

  discovery_output=$(
    "$skills_cli" add "$source" --list
  )
  if ! grep -Fq 'work-with-folderbase' <<<"$discovery_output"; then
    printf \
      'The Skills CLI did not discover work-with-folderbase through %s.\n' \
      "$description" >&2
    exit 1
  fi
}

verify_discovery "$repository_root" 'the local checkout'
verify_discovery "$published_source" 'the exact published tag'
verify_discovery "$catalog_source" 'the canonical catalog shorthand'

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
verify_local_install opencode .agents/skills
verify_published_install codex .agents/skills
verify_published_install claude-code .claude/skills
verify_published_install cursor .agents/skills
verify_published_install hermes-agent .hermes/skills
verify_published_install openclaw skills
verify_published_install opencode .agents/skills

printf '%s\n' \
  'Local and version-pinned published Folderbase skill installs are valid.'
