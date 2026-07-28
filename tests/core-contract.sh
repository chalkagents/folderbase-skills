#!/usr/bin/env bash
set -euo pipefail

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

printf '%s\n' 'Folderbase skill and immutable Core contract are compatible.'
