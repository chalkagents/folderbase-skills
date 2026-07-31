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
  docs/test-evidence/core-v030-contract-red.md \
  docs/test-evidence/skills-v021-publication.md \
  docs/test-evidence/skills-v021-release-red.md \
  docs/test-evidence/skills-v030-publication.md \
  docs/test-evidence/skills-v030-release-red.md \
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

release_source='https://github.com/chalkagents/folderbase-skills/tree/v0.3.0'
release_core_commit='91530adbd984fdd61f22ecd73dd48c80e8364416'
normalized_readme_text=$(
  tr '\n' ' ' <"$repository_root/README.md" |
    tr -s '[:space:]' ' '
)
grep -F -q -- 'current Folderbase Skills release is `v0.3.0`' \
  <<<"$normalized_readme_text"
grep -F -q -- "$release_source" "$repository_root/README.md"
grep -F -q -- "$release_core_commit" "$repository_root/README.md"
if grep -F -q -- \
  'becomes installable only after this reviewed head is merged and tagged' \
  <<<"$normalized_readme_text"; then
  printf '%s\n' 'README still carries the during-release availability warning.' >&2
  exit 1
fi
grep -F -x -q -- '## Contract' "$repository_root/README.md"
if grep -F -x -q -- '## Development contract' "$repository_root/README.md"; then
  printf '%s\n' 'README still describes the release pairing as developmental.' >&2
  exit 1
fi

published_baseline_source='https://github.com/chalkagents/folderbase-skills/tree/v0.3.0'
grep -F -q -- "$published_baseline_source" "$repository_root/tests/distribution.sh"
grep -F -q -- \
  'Local and version-pinned published Folderbase skill installs are valid.' \
  "$repository_root/tests/distribution.sh"
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
for rejected_guidance in \
  'only when both `FOLDERBASE.md` and `.folderbase/manifest.json` exist' \
  'Read `FOLDERBASE.md` first'
do
  if grep -F -q -- "$rejected_guidance" <<<"$normalized_skill_text"; then
    printf 'Skill retains obsolete Core 0.3 boundary guidance: %s\n' \
      "$rejected_guidance" >&2
    exit 1
  fi
done

for core_v05_discovery_claim in \
  '`.folderbase/manifest.json` is the sole Folderbase boundary marker' \
  'A manifest-only Folderbase is valid' \
  '`FOLDERBASE.md` and `.folderbaseignore` are optional ordinary files' \
  'Neither optional file is authoritative' \
  '`missing_manifest` is an ordinary unmanaged inspection state' \
  'List metadata before reading file content' \
  'Never initialize without explicit user intent'
do
  grep -F -q -- "$core_v05_discovery_claim" <<<"$normalized_skill_text"
done

for required_text in \
  'references/protocol-surface.md' \
  'FOLDERBASE.md' \
  '.folderbase/manifest.json' \
  'folderbase init --help' \
  'folderbase inspect' \
  'folderbase init' \
  'folderbase --version' \
  'folderbase 0.3.0' \
  'folderbase attest' \
  'point-in-time continuity evidence' \
  'never authorization' \
  'including reads and writes' \
  'does not prove ordinary file content is unchanged' \
  'across devices' \
  'folder-to-Folderbase adoption' \
  'must not use `transform`' \
  'cannot share or synchronize' \
  'managed Live Folder sharing' \
  'separately authenticated Folderbase Platform' \
  'OS or harness authority' \
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
  '91530adbd984fdd61f22ecd73dd48c80e8364416' \
  'v0.3.0' \
  'Protocol 0.1' \
  'Template Protocol 0.2' \
  'Reorganization Protocol 0.3' \
  '0.3.0'
do
  grep -F -q -- "$required_text" "$protocol_reference"
done

for core_v05_candidate_claim in \
  'v0.5.0-rc.1' \
  '45de7804bb4e57224e5b9495e4394441ce652f0b' \
  'folderbase 0.5.0-rc.1' \
  'read-only discovery candidate' \
  'sole Folderbase boundary marker' \
  'manifest-only Folderbase is valid' \
  'optional ordinary non-authoritative files' \
  'missing_manifest' \
  'metadata before content'
do
  grep -F -q -- "$core_v05_candidate_claim" "$protocol_reference"
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
grep -F -q -- 'CORE_V030_CONTRACT_RED_EXIT=1' \
  "$repository_root/docs/test-evidence/core-v030-contract-red.md"
grep -F -q -- 'SKILLS_V021_RELEASE_RED_EXIT=1' \
  "$repository_root/docs/test-evidence/skills-v021-release-red.md"
grep -F -q -- 'f7a2749548e96c1841fc8675f4a2242119b10aaa' \
  "$repository_root/docs/test-evidence/skills-v021-release-red.md"
grep -F -q -- 'SKILLS_V030_RELEASE_RED_EXIT=1' \
  "$repository_root/docs/test-evidence/skills-v030-release-red.md"
grep -F -q -- '91809afe91fec56cd1bfaac5d9328055bb2c79fc' \
  "$repository_root/docs/test-evidence/skills-v030-release-red.md"
publication_evidence="$repository_root/docs/test-evidence/skills-v021-publication.md"
for publication_claim in \
  'ACCEPTANCE_PUBLICATION_RED_EXIT=1' \
  'DISTRIBUTION_PUBLICATION_RED_EXIT=1' \
  'DISTRIBUTION_PUBLICATION_GREEN_EXIT=0' \
  '1bc5a960226d0d5a396f06f0a068bdef2129069c' \
  '172382a5548b7761527173a810d72e3739564f70' \
  '30410246722' \
  '30410323435' \
  'd829f6f4a218b8771e11f42de905ab2b24e15707a05e16dfb180414ba8749fde' \
  '6127734f977c9b2bf983043e1f30666ab920efc7f732943bab630fa923d29a97' \
  'a41b2bc5d83dad6df2a2a3ceca0618980b9f54db4063a82d0133c5239c7b2821'
do
  grep -F -q -- "$publication_claim" "$publication_evidence"
done
publication_v030_evidence="$repository_root/docs/test-evidence/skills-v030-publication.md"
for publication_claim in \
  'ACCEPTANCE_V030_PUBLICATION_RED_EXIT=1' \
  'DISTRIBUTION_V030_PUBLICATION_RED_EXIT=1' \
  'DISTRIBUTION_V030_PUBLICATION_GREEN_EXIT=0' \
  'b878e9599624b2b4d225b0c69d693f67f5268a9e' \
  '01a97dc6b8b86b9a0f2d3f2bc9f266395718d587' \
  '30459523188' \
  '30459657581' \
  '0e3e8035100107c6dc1ff7aeb0fb968c058b7f9d7654f781323b0381b63b3e0f' \
  '35718d726a76346fd1177636caaa6a61af9a6d20aa8cdf55a0273e05656a34ae' \
  '7aa27908fe0da69a1da0a7795de046227a186b519cc3c0b269be416202396f6c'
do
  grep -F -q -- "$publication_claim" "$publication_v030_evidence"
done

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
