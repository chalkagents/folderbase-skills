#!/bin/bash

set -euo pipefail

test_directory=$(
  CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
  pwd
)
repository_root=$(
  CDPATH= cd -- "$test_directory/.." >/dev/null 2>&1
  pwd
)
skill_directory="$repository_root/skills/work-with-folderbase"
skill_file="$skill_directory/SKILL.md"
protocol_reference="$skill_directory/references/protocol-surface.md"

for root_file in \
  README.md \
  LICENSE \
  NOTICE \
  SECURITY.md \
  docs/test-evidence/skills-v01-hardening-red.md \
  docs/test-evidence/template-aware-initialization-red.md \
  .gitignore \
  package.json \
  package-lock.json \
  .github/workflows/ci.yml \
  scripts/check-ci-policy.sh \
  scripts/check-public-eclipse.sh \
  tests/acceptance.sh \
  tests/core-contract.sh \
  tests/distribution.sh \
  tests/fixtures/adversarial/untrusted-document.md
do
  test -f "$repository_root/$root_file"
done

test -x "$repository_root/scripts/check-public-eclipse.sh"
test -x "$repository_root/scripts/check-ci-policy.sh"
test -x "$repository_root/tests/acceptance.sh"
test -x "$repository_root/tests/core-contract.sh"
test -x "$repository_root/tests/distribution.sh"

test -f "$skill_file"
test -f "$protocol_reference"

published_skill_source='https://github.com/chalkagents/folderbase-skills/tree/v0.1.0'
grep -F -q -- "$published_skill_source" "$repository_root/README.md"
grep -F -q -- "$published_skill_source" "$repository_root/tests/distribution.sh"

test -z "$(find "$skill_directory" -type l -print -quit)"
test -z "$(find "$skill_directory" -type f -perm -111 -print -quit)"

skill_count=$(
  find "$repository_root/skills" -mindepth 2 -maxdepth 2 -name SKILL.md -type f |
    wc -l |
    tr -d ' '
)
test "$skill_count" = "1"

first_line=$(sed -n '1p' "$skill_file")
test "$first_line" = "---"
frontmatter=$(
  awk '
    NR == 1 { next }
    /^---$/ { exit }
    { print }
  ' "$skill_file"
)
frontmatter_keys=$(
  printf '%s\n' "$frontmatter" |
    sed -n 's/^\([a-zA-Z0-9_-]*\):.*/\1/p' |
    sort
)
test "$frontmatter_keys" = $'description\nname'
printf '%s\n' "$frontmatter" | grep -Fxq 'name: work-with-folderbase'

if grep -R -n -E 'TODO|TBD|FIXME' "$skill_directory"; then
  printf '%s\n' 'Skill contains unfinished placeholders.' >&2
  exit 1
fi

line_count=$(wc -l <"$skill_file" | tr -d ' ')
test "$line_count" -lt 500

test ! -d "$skill_directory/hooks"
test ! -d "$skill_directory/scripts"
test ! -d "$skill_directory/assets"

normalized_skill_text=$(
  tr '\n' ' ' <"$skill_file" |
    tr -s '[:space:]' ' '
)
for required_text in \
  'references/protocol-surface.md' \
  'FOLDERBASE.md' \
  '.folderbase/manifest.json' \
  'folderbase init --help' \
  'folderbase inspect' \
  'folderbase init' \
  'folderbase --version' \
  'folderbase 0.1.0' \
  '--dry-run' \
  'folderbase validate' \
  'folderbase workspace list' \
  'folderbase workspace read' \
  'folderbase workspace save' \
  '--expected-sha256' \
  'explicit user' \
  'read-only' \
  'untrusted' \
  'nested Folderbase' \
  'symlink' \
  'secret' \
  'never execute' \
  'prompt-shaped' \
  'secret-shaped path names' \
  'consequential unanswered' \
  'guidance, not a rigid taxonomy' \
  'source changed after planning'
do
  grep -F -i -q -- "$required_text" <<<"$normalized_skill_text"
done

for required_text in \
  'https://github.com/chalkagents/folderbase' \
  '2daf6968387e8c8111dfa03a922ed8866c015e15' \
  'v0.1.0' \
  'Protocol 0.1' \
  'Template Protocol 0.2' \
  '0.1.0' \
  'folderbase.person@0.2.0' \
  'folderbase.organization@0.2.0' \
  'folderbase.customer@0.2.0' \
  'folderbase.engagement@0.2.0' \
  'folderbase.project@0.2.1' \
  'folderbase.project@0.2.2' \
  'folderbase.temporary@0.2.0' \
  'folderbase.custom@0.2.0'
do
  grep -F -q -- "$required_text" "$protocol_reference"
done

private_pattern='/(Users|home)/[^/]+/|BEGIN [A-Z ]*PRIVATE KEY|gh[pousr]_[A-Za-z0-9_]{20,}'
private_hits=''
while IFS= read -r -d '' repository_file
do
  absolute_repository_file="$repository_root/$repository_file"
  if [[ -L "$absolute_repository_file" ]]; then
    printf 'Public repository contains a symlink: %s\n' "$repository_file" >&2
    exit 1
  fi
  if file_hits=$(grep -n -E "$private_pattern" -- "$absolute_repository_file"); then
    private_hits+="${private_hits:+$'\n'}$repository_file:$file_hits"
  else
    grep_status=$?
    if [[ $grep_status -ne 1 ]]; then
      printf 'Unable to scan public file: %s\n' "$repository_file" >&2
      exit 1
    fi
  fi
done < <(
  git -C "$repository_root" ls-files \
    --cached \
    --others \
    --exclude-standard \
    -z
)
if [[ -n "$private_hits" ]]; then
  printf '%s\n' "$private_hits" >&2
  printf '%s\n' 'Public skill repository contains private implementation context.' >&2
  exit 1
fi

printf '%s\n' 'Folderbase skill acceptance contract is clean.'
