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
template_cases_fixture="$repository_root/tests/fixtures/template-cases.tsv"
template_red_evidence="$repository_root/docs/test-evidence/template-aware-initialization-red.md"

for root_file in \
  README.md \
  LICENSE \
  NOTICE \
  SECURITY.md \
  docs/test-evidence/core-v02-contract-red.md \
  docs/test-evidence/core-v021-contract-red.md \
  docs/test-evidence/skills-v021-release-red.md \
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
  tests/fixtures/adversarial/untrusted-document.md \
  tests/fixtures/template-cases.tsv
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

release_source='https://github.com/chalkagents/folderbase-skills/tree/v0.2.1'
release_core_commit='3a3e9df836a1fe0a2f33946205f899cc9483dc1b'
normalized_readme_text=$(
  tr '\n' ' ' <"$repository_root/README.md" |
    tr -s '[:space:]' ' '
)
grep -F -q -- 'current Folderbase Skills release is `v0.2.1`' \
  <<<"$normalized_readme_text"
grep -F -q -- "$release_source" "$repository_root/README.md"
grep -F -q -- "$release_core_commit" "$repository_root/README.md"
grep -F -q -- 'becomes installable only after this reviewed head is merged and tagged' \
  <<<"$normalized_readme_text"
grep -F -x -q -- '## Contract' "$repository_root/README.md"
if grep -F -x -q -- '## Development contract' "$repository_root/README.md"; then
  printf '%s\n' 'README still describes the public pairing as developmental.' >&2
  exit 1
fi

published_baseline_source='https://github.com/chalkagents/folderbase-skills/tree/v0.2.0'
grep -F -q -- "$published_baseline_source" "$repository_root/tests/distribution.sh"
for tested_agent in \
  'Codex' \
  'Claude Code' \
  'Cursor' \
  'Hermes Agent' \
  'OpenClaw'
do
  grep -F -q -- "$tested_agent" "$repository_root/README.md"
done

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
  'folderbase 0.2.1' \
  '--dry-run' \
  'Preview, then initialize only after explicit user approval' \
  'plan_digest' \
  '--expected-plan-digest' \
  'applied_plan_digest' \
  'outcome is unknown' \
  'exact approval-bound initialization outcome remains unknown' \
  'process has terminated' \
  'never run initialization again' \
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
  '--no-agent-adapters' \
  'quotes, equals signs, literal $(), and newlines' \
  'guidance, not a rigid taxonomy' \
  'source changed after planning'
do
  grep -F -i -q -- "$required_text" <<<"$normalized_skill_text"
done

for template_kind in \
  person \
  organization \
  customer \
  engagement \
  project \
  temporary \
  custom
do
  grep -F -q -- "\`$template_kind\`" "$skill_file"
done

for required_text in \
  'https://github.com/chalkagents/folderbase' \
  '3a3e9df836a1fe0a2f33946205f899cc9483dc1b' \
  'v0.2.1' \
  'Protocol 0.1' \
  'Template Protocol 0.2' \
  '0.2.1'
do
  grep -F -q -- "$required_text" "$protocol_reference"
done

while IFS=$'\t' read -r template_selector _template_kind _mode \
  _extra_question _extra_answer
do
  [[ "$template_selector" = \#* ]] && continue
  test -n "$template_selector"
  grep -F -q -- "$template_selector" "$protocol_reference"
done <"$template_cases_fixture"

test "$(
  grep -F -c -- 'worktree add --detach' "$template_red_evidence"
)" -ge 2
test "$(
  grep -F -c -- 'git apply' "$template_red_evidence"
)" -ge 2
grep -F -q -- 'ACCEPTANCE_RED_EXIT=1' "$template_red_evidence"
grep -F -q -- 'CORE_CONTRACT_RED_EXIT=1' "$template_red_evidence"
grep -F -q -- 'worktree remove --force' "$template_red_evidence"
grep -F -q -- 'CORE_V02_CONTRACT_RED_EXIT=1' \
  "$repository_root/docs/test-evidence/core-v02-contract-red.md"
grep -F -q -- 'CORE_V021_CONTRACT_RED_EXIT=1' \
  "$repository_root/docs/test-evidence/core-v021-contract-red.md"
grep -F -q -- 'SKILLS_V021_RELEASE_RED_EXIT=1' \
  "$repository_root/docs/test-evidence/skills-v021-release-red.md"
grep -F -q -- 'f7a2749548e96c1841fc8675f4a2242119b10aaa' \
  "$repository_root/docs/test-evidence/skills-v021-release-red.md"

for local_install_contract in \
  'verify_local_install codex .agents/skills' \
  'verify_local_install claude-code .claude/skills' \
  'verify_local_install cursor .agents/skills' \
  'verify_local_install hermes-agent .hermes/skills' \
  'verify_local_install openclaw skills'
do
  grep -F -q -- "$local_install_contract" \
    "$repository_root/tests/distribution.sh"
done
for published_install_contract in \
  'verify_published_install codex .agents/skills' \
  'verify_published_install claude-code .claude/skills' \
  'verify_published_install cursor .agents/skills' \
  'verify_published_install hermes-agent .hermes/skills' \
  'verify_published_install openclaw skills'
do
  grep -F -q -- "$published_install_contract" \
    "$repository_root/tests/distribution.sh"
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
