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
protocol_reference="$repository_root/skills/work-with-folderbase/references/protocol-surface.md"
temporary_root=$(mktemp -d)
trap 'rm -R "$temporary_root"' EXIT

core_repository=https://github.com/chalkagents/folderbase.git
core_ref=${FOLDERBASE_CORE_REF:-2daf6968387e8c8111dfa03a922ed8866c015e15}

for template_selector in \
  'folderbase.person@0.2.0' \
  'folderbase.organization@0.2.0' \
  'folderbase.customer@0.2.0' \
  'folderbase.engagement@0.2.0' \
  'folderbase.project@0.2.1' \
  'folderbase.project@0.2.2' \
  'folderbase.temporary@0.2.0' \
  'folderbase.custom@0.2.0'
do
  grep -Fq -- "$template_selector" "$protocol_reference"
done

if [[ -n "${FOLDERBASE_CLI_BIN:-}" ]]; then
  folderbase=$FOLDERBASE_CLI_BIN
else
  if [[ ! "$core_ref" =~ ^[0-9a-f]{40}$ ]]; then
    printf '%s\n' 'FOLDERBASE_CORE_REF must be an immutable 40-character commit.' >&2
    exit 1
  fi
  install_root="$temporary_root/install"

  cargo install \
    --git "$core_repository" \
    --rev "$core_ref" \
    --locked \
    --root "$install_root" \
    folderbase-cli
  folderbase="$install_root/bin/folderbase"
fi

test -x "$folderbase"
test "$("$folderbase" --version)" = 'folderbase 0.1.0'

"$folderbase" --help >"$temporary_root/folderbase-help.txt"
"$folderbase" init --help >"$temporary_root/init-help.txt"
for command in inspect init validate transform version workspace
do
  grep -Fq "$command" "$temporary_root/folderbase-help.txt"
done
for init_surface in \
  '--dry-run' \
  '--name' \
  '--kind' \
  '--template' \
  '--answer' \
  '--json'
do
  grep -Fq -- "$init_surface" "$temporary_root/init-help.txt"
done
grep -Fq \
  'person, organization, engagement, project, customer, temporary, custom' \
  "$temporary_root/init-help.txt"

template_cases=(
  'folderbase.person@0.2.0|person||'
  'folderbase.organization@0.2.0|organization||'
  'folderbase.customer@0.2.0|customer|boundary_reason|This context has an independent retention boundary.'
  'folderbase.engagement@0.2.0|engagement||'
  'folderbase.project@0.2.2|project||'
  'folderbase.temporary@0.2.0|temporary||'
  'folderbase.custom@0.2.0|custom||'
)

for template_case in "${template_cases[@]}"
do
  IFS='|' read -r template_selector template_kind extra_question extra_answer \
    <<<"$template_case"
  manifest_kind=$template_kind
  template_workspace="$temporary_root/template-$template_kind"
  mkdir -p "$template_workspace"
  printf 'existing %s bytes\n' "$template_kind" \
    >"$template_workspace/existing-content.txt"

  template_arguments=(
    "$template_workspace"
    --name "Starter $template_kind"
    --kind "$manifest_kind"
    --template "$template_selector"
    --answer 'purpose=Make this folder understandable.'
    --answer 'current_state=The template is being previewed.'
    --answer 'next_action=Review the additive plan.'
    --json
  )
  if [[ -n "$extra_question" ]]; then
    template_arguments+=(
      --answer "$extra_question=$extra_answer"
    )
  fi

  "$folderbase" init \
    "${template_arguments[@]:0:1}" \
    --dry-run \
    "${template_arguments[@]:1}" \
    >"$temporary_root/template-$template_kind-dry-run.json"
  test ! -e "$template_workspace/.folderbase"
  test ! -e "$template_workspace/FOLDERBASE.md"
  test "$(
    cat "$template_workspace/existing-content.txt"
  )" = "existing $template_kind bytes"

  "$folderbase" init "${template_arguments[@]}" \
    >"$temporary_root/template-$template_kind-init.json"
  "$folderbase" validate "$template_workspace" --json \
    >"$temporary_root/template-$template_kind-validate.json"
  python3 - \
    "$template_workspace/.folderbase/manifest.json" \
    "$temporary_root/template-$template_kind-validate.json" \
    "$template_selector" \
    "$manifest_kind" <<'PY'
import json
import sys

manifest = json.load(open(sys.argv[1], encoding="utf-8"))
validation = json.load(open(sys.argv[2], encoding="utf-8"))
template_id, template_version = sys.argv[3].split("@", 1)

assert validation["valid"] is True
assert manifest["folderbase"]["kind"] == sys.argv[4]
assert manifest["folderbase"]["template_provenance"]["id"] == template_id
assert manifest["folderbase"]["template_provenance"]["version"] == template_version
PY
  test "$(
    cat "$template_workspace/existing-content.txt"
  )" = "existing $template_kind bytes"
done

superseded_project_workspace="$temporary_root/template-project-superseded"
mkdir -p "$superseded_project_workspace"
printf '%s\n' 'superseded preview must stay read-only' \
  >"$superseded_project_workspace/existing-content.txt"
"$folderbase" init \
  "$superseded_project_workspace" \
  --kind project \
  --template folderbase.project@0.2.1 \
  --answer 'purpose=Identify the superseded built-in without applying it.' \
  --answer 'current_state=The newer validated starter is available.' \
  --answer 'next_action=Use exact project template version 0.2.2.' \
  --dry-run \
  --json \
  >"$temporary_root/template-project-superseded-dry-run.json"
test ! -e "$superseded_project_workspace/.folderbase"
test ! -e "$superseded_project_workspace/FOLDERBASE.md"
test "$(
  cat "$superseded_project_workspace/existing-content.txt"
)" = 'superseded preview must stay read-only'

unsupported_custom_workspace="$temporary_root/unsupported-custom-template"
mkdir -p "$unsupported_custom_workspace"
printf '%s\n' 'must stay untouched' \
  >"$unsupported_custom_workspace/existing-content.txt"
if "$folderbase" init \
  "$unsupported_custom_workspace" \
  --template folderbase.custom@0.2.1 \
  --answer 'purpose=Do not guess an unavailable custom template.' \
  --answer 'current_state=The requested exact version is unavailable.' \
  --answer 'next_action=Report the unsupported selector.' \
  --json \
  >"$temporary_root/unsupported-custom-template.json" \
  2>"$temporary_root/unsupported-custom-template.err"
then
  printf '%s\n' 'An unavailable custom template version unexpectedly initialized.' >&2
  exit 1
fi
test ! -e "$unsupported_custom_workspace/.folderbase"
test ! -e "$unsupported_custom_workspace/FOLDERBASE.md"
test "$(
  cat "$unsupported_custom_workspace/existing-content.txt"
)" = 'must stay untouched'

workspace="$temporary_root/workspace"
mkdir -p "$workspace/nested"
printf '%s\n' 'private nested content' >"$workspace/nested/private.md"
"$folderbase" init "$workspace/nested" --json >"$temporary_root/nested-init.json"

printf '%s\n' 'alpha' >"$workspace/note.md"
printf '\000\001\002' >"$workspace/movie.bin"

"$folderbase" inspect "$workspace" --json >"$temporary_root/inspect.json"
"$folderbase" init "$workspace" --dry-run --json >"$temporary_root/dry-run.json"
test ! -e "$workspace/.folderbase"
test ! -e "$workspace/FOLDERBASE.md"
test "$(sed -n '1p' "$workspace/note.md")" = alpha

"$folderbase" init "$workspace" --json >"$temporary_root/init.json"
"$folderbase" validate "$workspace" --json >"$temporary_root/validate.json"
python3 -c \
  'import json,sys; assert json.load(open(sys.argv[1]))["valid"] is True' \
  "$temporary_root/validate.json"

"$folderbase" workspace list "$workspace" --json \
  >"$temporary_root/list.json"
python3 -c '
import json, sys
entries = json.load(open(sys.argv[1]))["entries"]
by_path = {entry["path"]: entry for entry in entries}
assert by_path["nested"]["kind"] == "folderbase"
assert "nested/private.md" not in by_path
assert by_path["movie.bin"]["bytes"] == 3
assert by_path["movie.bin"]["editable"] is False
' "$temporary_root/list.json"

if "$folderbase" workspace read "$workspace" movie.bin --json \
  >"$temporary_root/binary-read.json" 2>"$temporary_root/binary-read.err"
then
  printf '%s\n' 'Binary content was incorrectly exposed as editable text.' >&2
  exit 1
fi

"$folderbase" workspace read "$workspace" note.md --json \
  >"$temporary_root/read.json"
loaded_sha=$(
  python3 -c \
    'import json,sys; print(json.load(open(sys.argv[1]))["sha256"])' \
    "$temporary_root/read.json"
)

printf '%s\n' 'beta' |
  "$folderbase" workspace save \
    "$workspace" \
    note.md \
    --expected-sha256 "$loaded_sha" \
    --stdin \
    --json >"$temporary_root/save.json"
test "$(sed -n '1p' "$workspace/note.md")" = beta

if printf '%s\n' 'stale overwrite' |
  "$folderbase" workspace save \
    "$workspace" \
    note.md \
    --expected-sha256 "$loaded_sha" \
    --stdin \
    --json >"$temporary_root/stale-save.json" 2>"$temporary_root/stale-save.err"
then
  printf '%s\n' 'A stale optimistic-concurrency save unexpectedly succeeded.' >&2
  exit 1
fi
test "$(sed -n '1p' "$workspace/note.md")" = beta

transform_source="$temporary_root/transform-source"
mkdir -p "$transform_source/docs"
printf '%s\n' 'reviewed proposal' >"$transform_source/docs/proposal.md"

"$folderbase" transform analyze "$transform_source" --json \
  >"$temporary_root/transform-analysis.json"
test ! -e "$transform_source/.folderbase"
test ! -e "$transform_source/Organized"

python3 -c '
import json, sys
analysis = json.load(open(sys.argv[1]))
answers = [
    {
        "question_id": question["id"],
        "answer": question["recommended_option_id"],
    }
    for question in analysis["questions"]
]
json.dump(answers, open(sys.argv[2], "w"))
' \
  "$temporary_root/transform-analysis.json" \
  "$temporary_root/transform-answers.json"

"$folderbase" transform plan \
  "$transform_source" \
  --destination Organized \
  --answers-stdin \
  --json \
  <"$temporary_root/transform-answers.json" \
  >"$temporary_root/transform-plan.json"
test -d "$transform_source/.folderbase/migrations"
test ! -e "$transform_source/Organized"

migration_id=$(
  python3 -c \
    'import json,sys; print(json.load(open(sys.argv[1]))["id"])' \
    "$temporary_root/transform-plan.json"
)
"$folderbase" transform preview \
  "$transform_source" \
  "$migration_id" \
  --json >"$temporary_root/transform-preview.json"
"$folderbase" transform approve \
  "$transform_source" \
  "$migration_id" \
  --json >"$temporary_root/transform-approval.json"
"$folderbase" transform apply \
  "$transform_source" \
  "$migration_id" \
  --json >"$temporary_root/transform-apply.json"

python3 -c '
import json, sys
assert json.load(open(sys.argv[1]))["state"] == "verified"
' "$temporary_root/transform-apply.json"
test -f "$transform_source/docs/proposal.md"
test -f "$transform_source/Organized/docs/proposal.md"

"$folderbase" transform recover \
  "$transform_source" \
  "$migration_id" \
  --json >"$temporary_root/transform-recover.json"
python3 -c '
import json, sys
result = json.load(open(sys.argv[1]))
assert result["state"] == "verified"
assert "Organized/docs/proposal.md" in result["created_paths"]
' "$temporary_root/transform-recover.json"

"$folderbase" transform rollback \
  "$transform_source" \
  "$migration_id" \
  --json >"$temporary_root/transform-rollback.json"
python3 -c '
import json, sys
result = json.load(open(sys.argv[1]))
assert result["state"] == "rolled_back"
assert "Organized/docs/proposal.md" in result["removed_paths"]
' "$temporary_root/transform-rollback.json"
test -f "$transform_source/docs/proposal.md"
test ! -e "$transform_source/Organized"
test -f "$transform_source/.folderbase/migrations/$migration_id/plan.json"
test -f "$transform_source/.folderbase/migrations/$migration_id/result.json"

adversarial_workspace="$temporary_root/adversarial-workspace"
outside_workspace="$temporary_root/outside-workspace"
mkdir -p "$adversarial_workspace" "$outside_workspace"
secret_value=FOLDERBASE_SECRET_VALUE_SENTINEL
printf '%s\n' "$secret_value" >"$adversarial_workspace/.env"
cp \
  "$test_directory/fixtures/adversarial/untrusted-document.md" \
  "$adversarial_workspace/untrusted-document.md"
printf '%s\n' "$secret_value" >"$outside_workspace/private.txt"
ln -s \
  "$outside_workspace/private.txt" \
  "$adversarial_workspace/escape.txt"

"$folderbase" inspect "$adversarial_workspace" --json \
  >"$temporary_root/adversarial-inspect.json"
"$folderbase" transform analyze "$adversarial_workspace" --json \
  >"$temporary_root/adversarial-analysis.json"
"$folderbase" init "$adversarial_workspace" --dry-run --json \
  >"$temporary_root/adversarial-dry-run.json"

python3 - \
  "$temporary_root/adversarial-inspect.json" \
  "$temporary_root/adversarial-analysis.json" <<'PY'
import json
import sys

inspection = json.load(open(sys.argv[1], encoding="utf-8"))
classified = {
    entry["path"]: entry
    for entry in inspection["classified_paths"]
}
assert inspection["inventory"]["secret_shaped_file_count"] == 1
assert classified[".env"]["classification"] == "secret_shaped"
assert classified[".env"]["reason"].endswith("contents were not read.")
assert any(
    warning == "Skipped symbolic link without following it: escape.txt"
    for warning in inspection["warnings"]
)

analysis = json.load(open(sys.argv[2], encoding="utf-8"))
secret_questions = [
    question
    for question in analysis["questions"]
    if question["id"] == "question_secrets"
]
assert len(secret_questions) == 1
assert secret_questions[0]["recommended_option_id"] == "local_only"
PY

for metadata_output in \
  "$temporary_root/adversarial-inspect.json" \
  "$temporary_root/adversarial-analysis.json" \
  "$temporary_root/adversarial-dry-run.json"
do
  if grep -Fq "$secret_value" "$metadata_output"; then
    printf 'Secret contents leaked into metadata output: %s\n' \
      "$metadata_output" >&2
    exit 1
  fi
  if grep -Fq 'FOLDERBASE_PROMPT_SENTINEL' "$metadata_output"; then
    printf 'Document contents leaked into metadata output: %s\n' \
      "$metadata_output" >&2
    exit 1
  fi
done

"$folderbase" init "$adversarial_workspace" --json \
  >"$temporary_root/adversarial-init.json"
"$folderbase" workspace list "$adversarial_workspace" --json \
  >"$temporary_root/adversarial-list.json"
python3 -c '
import json, sys
entries = json.load(open(sys.argv[1], encoding="utf-8"))["entries"]
by_path = {entry["path"]: entry for entry in entries}
assert by_path["escape.txt"]["kind"] == "symlink"
assert by_path["escape.txt"]["editable"] is False
' "$temporary_root/adversarial-list.json"

if "$folderbase" workspace read \
  "$adversarial_workspace" \
  escape.txt \
  --json \
  >"$temporary_root/adversarial-symlink-read.json" \
  2>"$temporary_root/adversarial-symlink-read.err"
then
  printf '%s\n' 'A symlink escape was incorrectly readable.' >&2
  exit 1
fi
test ! -s "$temporary_root/adversarial-symlink-read.json"
grep -Fq 'path escapes the folderbase root' \
  "$temporary_root/adversarial-symlink-read.err"
if grep -Fq "$secret_value" "$temporary_root/adversarial-symlink-read.err"; then
  printf '%s\n' 'A symlink failure exposed target contents.' >&2
  exit 1
fi

"$folderbase" workspace read \
  "$adversarial_workspace" \
  untrusted-document.md \
  --json >"$temporary_root/adversarial-document-read.json"
grep -Fq 'FOLDERBASE_PROMPT_SENTINEL' \
  "$temporary_root/adversarial-document-read.json"
test ! -e "$adversarial_workspace/FOLDERBASE_PROMPT_SENTINEL"
test ! -e "$temporary_root/FOLDERBASE_PROMPT_SENTINEL"

template_workspace="$temporary_root/template-workspace"
mkdir -p "$template_workspace"
template_sentinel="$temporary_root/FOLDERBASE_TEMPLATE_SENTINEL"
template_prompt="\$(touch $template_sentinel)"
template_recursive='${purpose} must remain literal'
template_args=(
  "$template_workspace"
  --name "Adversarial Template"
  --template folderbase.custom@0.2.0
  --answer "purpose=$template_prompt"
  --answer "current_state=$template_recursive"
  --answer "next_action=Review as inert text"
  --json
)

"$folderbase" init \
  "${template_args[@]:0:1}" \
  --dry-run \
  "${template_args[@]:1}" \
  >"$temporary_root/template-dry-run.json"
test ! -e "$template_sentinel"
grep -Fq "$template_prompt" "$temporary_root/template-dry-run.json"
grep -Fq "$template_recursive" "$temporary_root/template-dry-run.json"

"$folderbase" init "${template_args[@]}" \
  >"$temporary_root/template-init.json"
test ! -e "$template_sentinel"
grep -Fq "$template_prompt" "$template_workspace/FOLDERBASE.md"
grep -Fq "$template_recursive" "$template_workspace/FOLDERBASE.md"
"$folderbase" validate "$template_workspace" --json \
  >"$temporary_root/template-validate.json"
python3 -c \
  'import json,sys; assert json.load(open(sys.argv[1]))["valid"] is True' \
  "$temporary_root/template-validate.json"

drift_source="$temporary_root/drift-source"
mkdir -p "$drift_source/docs"
printf '%s\n' 'approved source' >"$drift_source/docs/proposal.md"
"$folderbase" transform analyze "$drift_source" --json \
  >"$temporary_root/drift-analysis.json"
python3 -c '
import json, sys
analysis = json.load(open(sys.argv[1], encoding="utf-8"))
answers = [
    {
        "question_id": question["id"],
        "answer": question["recommended_option_id"],
    }
    for question in analysis["questions"]
]
json.dump(answers, open(sys.argv[2], "w", encoding="utf-8"))
' \
  "$temporary_root/drift-analysis.json" \
  "$temporary_root/drift-answers.json"
"$folderbase" transform plan \
  "$drift_source" \
  --destination Organized \
  --answers-stdin \
  --json \
  <"$temporary_root/drift-answers.json" \
  >"$temporary_root/drift-plan.json"
drift_migration_id=$(
  python3 -c \
    'import json,sys; print(json.load(open(sys.argv[1]))["id"])' \
    "$temporary_root/drift-plan.json"
)
"$folderbase" transform preview \
  "$drift_source" \
  "$drift_migration_id" \
  --json >"$temporary_root/drift-preview.json"
"$folderbase" transform approve \
  "$drift_source" \
  "$drift_migration_id" \
  --json >"$temporary_root/drift-approval.json"
printf '%s\n' 'changed after approval' >"$drift_source/docs/proposal.md"

if "$folderbase" transform apply \
  "$drift_source" \
  "$drift_migration_id" \
  --json \
  >"$temporary_root/drift-apply.json" \
  2>"$temporary_root/drift-apply.err"
then
  printf '%s\n' 'A drifted migration unexpectedly applied.' >&2
  exit 1
fi
test ! -s "$temporary_root/drift-apply.json"
grep -Fq '"code": "migration_source_changed"' \
  "$temporary_root/drift-apply.err"
test "$(sed -n '1p' "$drift_source/docs/proposal.md")" = \
  'changed after approval'
test ! -e "$drift_source/Organized"

printf '%s\n' 'Folderbase skill and immutable Core contract are compatible.'
