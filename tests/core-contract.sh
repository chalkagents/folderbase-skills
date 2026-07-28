#!/usr/bin/env bash
set -euo pipefail

test_directory=$(
  CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
  pwd
)
template_cases_fixture="$test_directory/fixtures/template-cases.tsv"
temporary_root=$(mktemp -d)
trap 'rm -R "$temporary_root"' EXIT

core_repository=https://github.com/chalkagents/folderbase.git
core_ref=${FOLDERBASE_CORE_REF:-2daf6968387e8c8111dfa03a922ed8866c015e15}

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
  '--no-agent-adapters' \
  '--template' \
  '--answer' \
  '--json'
do
  grep -Fq -- "$init_surface" "$temporary_root/init-help.txt"
done
grep -Fq \
  'person, organization, engagement, project, customer, temporary, custom' \
  "$temporary_root/init-help.txt"

while IFS=$'\t' read -r \
  template_selector \
  template_kind \
  template_mode \
  extra_question \
  extra_answer
do
  [[ "$template_selector" = \#* ]] && continue
  test -n "$template_selector"
  test -n "$template_kind"
  test "$template_mode" = apply || test "$template_mode" = preview-only

  manifest_kind=$template_kind
  template_slug=${template_selector#folderbase.}
  template_slug=${template_slug//@/-}
  template_workspace="$temporary_root/template-$template_slug"
  mkdir -p "$template_workspace"
  printf 'existing %s bytes\n' "$template_kind" \
    >"$template_workspace/existing-content.txt"

  preserved_template_path=-
  preserved_template_sha=-
  if [[ "$template_selector" = 'folderbase.person@0.2.0' ]]; then
    mkdir -p "$template_workspace/Areas"
    printf 'original template target bytes\nline two\n' \
      >"$template_workspace/Areas/original.txt"
    preserved_template_path=Areas/original.txt
    preserved_template_sha=$(
      shasum -a 256 "$template_workspace/$preserved_template_path" |
        awk '{ print $1 }'
    )
  fi

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
  if [[ "$extra_question" != - ]]; then
    template_arguments+=(
      --answer "$extra_question=$extra_answer"
    )
  fi

  "$folderbase" init \
    "${template_arguments[@]:0:1}" \
    --dry-run \
    "${template_arguments[@]:1}" \
    >"$temporary_root/template-$template_slug-dry-run.json"
  test ! -e "$template_workspace/.folderbase"
  test ! -e "$template_workspace/FOLDERBASE.md"
  test "$(
    cat "$template_workspace/existing-content.txt"
  )" = "existing $template_kind bytes"

  if [[ "$preserved_template_path" != - ]]; then
    python3 - \
      "$temporary_root/template-$template_slug-dry-run.json" \
      "$preserved_template_path" <<'PY'
import json
import sys

preview = json.load(open(sys.argv[1], encoding="utf-8"))
assert sys.argv[2] in {
    preserved["path"]
    for preserved in preview["preserved_paths"]
}
assert {
    (precondition["path"], precondition["kind"])
    for precondition in preview["template_preconditions"]
} >= {("Areas", "directory")}
PY
    test "$(
      shasum -a 256 "$template_workspace/$preserved_template_path" |
        awk '{ print $1 }'
    )" = "$preserved_template_sha"
  fi

  if [[ "$template_mode" = preview-only ]]; then
    continue
  fi

  "$folderbase" init "${template_arguments[@]}" \
    >"$temporary_root/template-$template_slug-init.json"
  "$folderbase" validate "$template_workspace" --json \
    >"$temporary_root/template-$template_slug-validate.json"
  python3 - \
    "$template_workspace/.folderbase/manifest.json" \
    "$temporary_root/template-$template_slug-validate.json" \
    "$temporary_root/template-$template_slug-init.json" \
    "$template_selector" \
    "$manifest_kind" \
    "$preserved_template_path" <<'PY'
import json
import sys

manifest = json.load(open(sys.argv[1], encoding="utf-8"))
validation = json.load(open(sys.argv[2], encoding="utf-8"))
result = json.load(open(sys.argv[3], encoding="utf-8"))
template_id, template_version = sys.argv[4].split("@", 1)

assert validation["valid"] is True
assert manifest["folderbase"]["kind"] == sys.argv[5]
assert manifest["folderbase"]["template_provenance"]["id"] == template_id
assert manifest["folderbase"]["template_provenance"]["version"] == template_version
assert {
    (adapter["agent"], adapter["path"])
    for adapter in manifest["adapters"]
} == {
    ("codex", "AGENTS.md"),
    ("claude", "CLAUDE.md"),
}
assert {"AGENTS.md", "CLAUDE.md"} <= set(result["created_paths"])
if sys.argv[6] != "-":
    assert sys.argv[6] in result["preserved_paths"]
PY
  test "$(
    cat "$template_workspace/existing-content.txt"
  )" = "existing $template_kind bytes"
  if [[ "$preserved_template_path" != - ]]; then
    test "$(
      shasum -a 256 "$template_workspace/$preserved_template_path" |
        awk '{ print $1 }'
    )" = "$preserved_template_sha"
  fi
done <"$template_cases_fixture"

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

no_adapter_workspace="$temporary_root/no-agent-adapters"
mkdir -p "$no_adapter_workspace"
printf '%s\n' 'existing Codex instructions stay byte-identical' \
  >"$no_adapter_workspace/AGENTS.md"
printf '%s\n' 'existing Claude instructions stay byte-identical' \
  >"$no_adapter_workspace/CLAUDE.md"
no_adapter_agents_sha=$(
  shasum -a 256 "$no_adapter_workspace/AGENTS.md" |
    awk '{ print $1 }'
)
no_adapter_claude_sha=$(
  shasum -a 256 "$no_adapter_workspace/CLAUDE.md" |
    awk '{ print $1 }'
)
no_adapter_arguments=(
  "$no_adapter_workspace"
  --name 'No agent adapters'
  --kind custom
  --template folderbase.custom@0.2.0
  --answer 'purpose=Initialize without creating or changing agent adapters.'
  --answer 'current_state=Existing adapter files belong to the user.'
  --answer 'next_action=Preserve both adapter files.'
  --no-agent-adapters
  --json
)
"$folderbase" init \
  "${no_adapter_arguments[@]:0:1}" \
  --dry-run \
  "${no_adapter_arguments[@]:1}" \
  >"$temporary_root/no-agent-adapters-dry-run.json"
"$folderbase" init "${no_adapter_arguments[@]}" \
  >"$temporary_root/no-agent-adapters-init.json"
"$folderbase" validate "$no_adapter_workspace" --json \
  >"$temporary_root/no-agent-adapters-validate.json"
python3 - \
  "$temporary_root/no-agent-adapters-dry-run.json" \
  "$temporary_root/no-agent-adapters-init.json" \
  "$no_adapter_workspace/.folderbase/manifest.json" \
  "$temporary_root/no-agent-adapters-validate.json" <<'PY'
import json
import sys

preview = json.load(open(sys.argv[1], encoding="utf-8"))
result = json.load(open(sys.argv[2], encoding="utf-8"))
manifest = json.load(open(sys.argv[3], encoding="utf-8"))
validation = json.load(open(sys.argv[4], encoding="utf-8"))
adapter_paths = {"AGENTS.md", "CLAUDE.md"}

assert adapter_paths <= {
    preserved["path"]
    for preserved in preview["preserved_paths"]
}
assert not adapter_paths & {
    write["path"]
    for write in preview["writes"]
}
assert preview["warnings"] == [
    "Agent adapters were disabled for this initialization."
]
assert adapter_paths <= set(result["preserved_paths"])
assert not adapter_paths & set(result["created_paths"])
assert manifest["adapters"] == []
assert validation["valid"] is True
PY
test "$(
  shasum -a 256 "$no_adapter_workspace/AGENTS.md" |
    awk '{ print $1 }'
)" = "$no_adapter_agents_sha"
test "$(
  shasum -a 256 "$no_adapter_workspace/CLAUDE.md" |
    awk '{ print $1 }'
)" = "$no_adapter_claude_sha"

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
template_file_sentinel="$temporary_root/FOLDERBASE_TEMPLATE_FILE_SENTINEL"
template_process_sentinel="$temporary_root/FOLDERBASE_TEMPLATE_PROCESS_SENTINEL"
printf -v template_prompt '%s\n%s\n%s\n%s' \
  'Quotes: "double" and '\''single'\''; equals=a=b=c' \
  "Command shaped text: sh -c 'touch $template_process_sentinel'" \
  "Literal \$() text: \$(touch $template_file_sentinel)" \
  'Final line remains inert.'
template_recursive=$'First line\n${purpose} must remain literal\nLast line: x=y=z'
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
test ! -e "$template_file_sentinel"
test ! -e "$template_process_sentinel"
python3 - \
  "$temporary_root/template-dry-run.json" \
  "$template_prompt" \
  "$template_recursive" <<'PY'
import json
import sys

preview = json.load(open(sys.argv[1], encoding="utf-8"))
entry = next(
    write["content"]
    for write in preview["writes"]
    if write["path"] == "FOLDERBASE.md"
)
expected = (
    f"## Purpose\n{sys.argv[2]}\n\n"
    f"## Current state\n{sys.argv[3]}\n\n"
)
assert expected.encode("utf-8") in entry.encode("utf-8")
PY

"$folderbase" init "${template_args[@]}" \
  >"$temporary_root/template-init.json"
test ! -e "$template_file_sentinel"
test ! -e "$template_process_sentinel"
python3 - \
  "$template_workspace/FOLDERBASE.md" \
  "$template_prompt" \
  "$template_recursive" <<'PY'
import sys

actual = open(sys.argv[1], "rb").read()
expected = (
    f"## Purpose\n{sys.argv[2]}\n\n"
    f"## Current state\n{sys.argv[3]}\n\n"
).encode("utf-8")
assert expected in actual
PY
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
