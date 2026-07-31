#!/usr/bin/env bash
set -euo pipefail

test_directory=$(
  CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
  pwd
)
template_cases_fixture="$test_directory/fixtures/template-cases.tsv"
# Captured from exact Core 45de7804bb4e57224e5b9495e4394441ce652f0b.
core_v05_manifest_fixture="$test_directory/fixtures/core-v05-manifest-only.json"
core_v05_manifest_sha256=200abe55ae436695c2a0cb8b57e3c942733db5b85770d396261cf6618f581e92
temporary_root=$(mktemp -d)
trap 'rm -R "$temporary_root"' EXIT

core_repository=https://github.com/chalkagents/folderbase.git
core_contract=${FOLDERBASE_CORE_CONTRACT:-v0.3}
core_v05_candidate_ref=45de7804bb4e57224e5b9495e4394441ce652f0b

run_core_v05_read_only_contract() {
  local configured_ref=${FOLDERBASE_CORE_REF:-$core_v05_candidate_ref}
  local folderbase_real

  if [[ "$configured_ref" != "$core_v05_candidate_ref" ]]; then
    printf 'Core 0.5 candidate proof requires exact commit %s.\n' \
      "$core_v05_candidate_ref" >&2
    exit 1
  fi

  if [[ -n "${FOLDERBASE_CORE_CLI:-}" ]]; then
    printf '%s\n' \
      'Core 0.5 exact-source proof does not accept executable overrides.' >&2
    exit 1
  fi

  local install_root="$temporary_root/core-v05-install"
  cargo install \
    --git "$core_repository" \
    --rev "$configured_ref" \
    --locked \
    --root "$install_root" \
    folderbase-cli
  folderbase_real="$install_root/bin/folderbase"
  test -x "$folderbase_real"

  local invocation_log="$temporary_root/core-v05-invocations.jsonl"
  local folderbase="$temporary_root/core-v05-folderbase-wrapper"
  cat >"$folderbase" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

python3 - "$FOLDERBASE_CORE_V05_INVOCATION_LOG" "$@" <<'PY'
import json
import sys

with open(sys.argv[1], "a", encoding="utf-8") as output:
    output.write(json.dumps(sys.argv[2:], separators=(",", ":")) + "\n")
PY
exec "$FOLDERBASE_CORE_V05_REAL_CLI" "$@"
SH
  chmod 700 "$folderbase"
  export FOLDERBASE_CORE_V05_INVOCATION_LOG="$invocation_log"
  export FOLDERBASE_CORE_V05_REAL_CLI="$folderbase_real"
  test "$("$folderbase" --version)" = 'folderbase 0.5.0-rc.1'

  python3 - "$core_v05_manifest_fixture" "$core_v05_manifest_sha256" <<'PY'
import hashlib
from pathlib import Path
import sys

actual = hashlib.sha256(Path(sys.argv[1]).read_bytes()).hexdigest()
assert actual == sys.argv[2], (actual, sys.argv[2])
PY

  local ordinary_root="$temporary_root/ordinary-folder"
  mkdir -p "$ordinary_root/docs"
  printf '%s\n' 'ordinary text' \
    >"$ordinary_root/docs/note.md"
  python3 - "$ordinary_root/sparse-archive.bin" <<'PY'
import os
from pathlib import Path
import sys

path = Path(sys.argv[1])
with path.open("wb") as output:
    output.truncate(10 * 1024**3)
metadata = os.stat(path)
assert metadata.st_size == 10_737_418_240
assert metadata.st_blocks * 512 < metadata.st_size
PY

  "$folderbase" workspace list "$ordinary_root" --json \
    >"$temporary_root/ordinary-list.json"
  python3 - \
    "$temporary_root/ordinary-list.json" \
    "$ordinary_root" <<'PY'
import json
import os
import sys

listing = json.load(open(sys.argv[1], encoding="utf-8"))
assert os.path.realpath(listing["root"]) == os.path.realpath(sys.argv[2])
by_path = {entry["path"]: entry for entry in listing["entries"]}
assert by_path["sparse-archive.bin"] == {
    "path": "sparse-archive.bin",
    "name": "sparse-archive.bin",
    "kind": "file",
    "bytes": 10_737_418_240,
    "editable": False,
    "reconstructable": False,
}
assert by_path["docs/note.md"]["bytes"] == 14
assert by_path["docs/note.md"]["editable"] is True
PY

  if "$folderbase" validate "$ordinary_root" --json \
    >"$temporary_root/ordinary-validate.json" \
    2>"$temporary_root/ordinary-validate.err"
  then
    printf '%s\n' 'An unmanaged ordinary folder unexpectedly validated.' >&2
    exit 1
  fi
  test ! -s "$temporary_root/ordinary-validate.err"
  python3 - "$temporary_root/ordinary-validate.json" "$ordinary_root" <<'PY'
import json
import os
import sys

validation = json.load(open(sys.argv[1], encoding="utf-8"))
assert os.path.realpath(validation["root"]) == os.path.realpath(sys.argv[2])
assert validation["level"] == "shallow"
assert validation["valid"] is False
assert validation["findings"] == [{
    "code": "missing_manifest",
    "severity": "error",
    "path": ".folderbase/manifest.json",
    "message": "A folderbase root must contain .folderbase/manifest.json.",
}]
PY
  test ! -e "$ordinary_root/.folderbase"
  test ! -e "$ordinary_root/FOLDERBASE.md"
  test ! -e "$ordinary_root/.folderbaseignore"

  local manifest_only_root="$temporary_root/manifest-only-folderbase"
  mkdir -p "$manifest_only_root/.folderbase"
  cp "$core_v05_manifest_fixture" \
    "$manifest_only_root/.folderbase/manifest.json"
  test -f "$manifest_only_root/.folderbase/manifest.json"
  test ! -e "$manifest_only_root/FOLDERBASE.md"
  test ! -e "$manifest_only_root/.folderbaseignore"
  test ! -e "$manifest_only_root/.folderbase/summary.md"
  test ! -e "$manifest_only_root/.folderbase/questions.jsonl"

  "$folderbase" validate "$manifest_only_root" --json \
    >"$temporary_root/manifest-only-validate.json"
  "$folderbase" attest "$manifest_only_root" --json \
    >"$temporary_root/manifest-only-attest.json"
  python3 - \
    "$temporary_root/manifest-only-validate.json" \
    "$temporary_root/manifest-only-attest.json" \
    "$manifest_only_root" <<'PY'
import json
import os
import re
import sys

validation = json.load(open(sys.argv[1], encoding="utf-8"))
attestation = json.load(open(sys.argv[2], encoding="utf-8"))
assert os.path.realpath(validation["root"]) == os.path.realpath(sys.argv[3])
assert validation == {
    "root": validation["root"],
    "level": "shallow",
    "valid": True,
    "findings": [],
}
assert os.path.realpath(attestation["root"]) == os.path.realpath(sys.argv[3])
assert set(attestation) == {
    "root",
    "folderbase_id",
    "protocol_version",
    "manifest_sha256",
    "root_instance_sha256",
}
assert attestation["folderbase_id"].startswith("folderbase_")
assert attestation["protocol_version"] == "0.5.0"
assert re.fullmatch(r"[0-9a-f]{64}", attestation["manifest_sha256"])
assert re.fullmatch(r"[0-9a-f]{64}", attestation["root_instance_sha256"])
PY

  python3 - \
    "$invocation_log" \
    "$ordinary_root" \
    "$manifest_only_root" \
    "$core_v05_manifest_sha256" <<'PY'
import hashlib
import json
from pathlib import Path
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    invocations = [json.loads(line) for line in source]

assert invocations == [
    ["--version"],
    ["workspace", "list", sys.argv[2], "--json"],
    ["validate", sys.argv[2], "--json"],
    ["validate", sys.argv[3], "--json"],
    ["attest", sys.argv[3], "--json"],
], invocations
actual_manifest_sha256 = hashlib.sha256(
    Path(sys.argv[3], ".folderbase", "manifest.json").read_bytes()
).hexdigest()
assert actual_manifest_sha256 == sys.argv[4]
PY

  printf '%s\n' \
    'Folderbase skill and exact Core 0.5 candidate read-only contract are compatible.'
}

if [[ "$core_contract" = v0.5-read-only ]]; then
  run_core_v05_read_only_contract
  exit 0
fi
if [[ "$core_contract" != v0.3 ]]; then
  printf 'Unknown FOLDERBASE_CORE_CONTRACT mode: %s\n' "$core_contract" >&2
  exit 1
fi
if [[ -n "${FOLDERBASE_CORE_CLI:-}" ]]; then
  printf '%s\n' \
    'FOLDERBASE_CORE_CLI requires FOLDERBASE_CORE_CONTRACT=v0.5-read-only.' \
    >&2
  exit 1
fi

core_ref=${FOLDERBASE_CORE_REF:-91530adbd984fdd61f22ecd73dd48c80e8364416}

read_plan_digest() {
  python3 - "$1" <<'PY'
import json
import re
import sys

plan = json.load(open(sys.argv[1], encoding="utf-8"))
identity = plan["plan_digest"]
assert identity["algorithm"] == "sha256"
assert re.fullmatch(r"[0-9a-f]{64}", identity["digest"])
print(identity["digest"])
PY
}

assert_json_error_code() {
  local error_file=$1
  local expected_code=$2

  python3 - "$error_file" "$expected_code" <<'PY'
import json
import sys

envelope = json.load(open(sys.argv[1], encoding="utf-8"))
assert envelope["error"]["code"] == sys.argv[2], envelope
assert isinstance(envelope["error"]["message"], str)
assert envelope["error"]["message"]
PY
}

snapshot_workspace() {
  local workspace_root=$1
  local snapshot_file=$2

  python3 - "$workspace_root" "$snapshot_file" <<'PY'
import hashlib
import json
import os
from pathlib import Path
import stat
import sys

root = Path(sys.argv[1])
entries = []
for path in sorted(root.rglob("*")):
    relative = path.relative_to(root).as_posix()
    metadata = os.lstat(path)
    record = {
        "path": relative,
        "mode": stat.S_IMODE(metadata.st_mode),
    }
    if stat.S_ISLNK(metadata.st_mode):
        record.update(kind="symlink", target=os.readlink(path))
    elif stat.S_ISDIR(metadata.st_mode):
        record.update(kind="directory")
    elif stat.S_ISREG(metadata.st_mode):
        record.update(
            kind="file",
            bytes=metadata.st_size,
            sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
        )
    else:
        record.update(kind="other")
    entries.append(record)

with open(sys.argv[2], "w", encoding="utf-8") as output:
    json.dump(entries, output, sort_keys=True, separators=(",", ":"))
PY
}

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
test "$("$folderbase" --version)" = 'folderbase 0.3.0'

"$folderbase" --help >"$temporary_root/folderbase-help.txt"
"$folderbase" init --help >"$temporary_root/init-help.txt"
for command in attest inspect init validate transform version workspace
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
  '--expected-plan-digest' \
  '--json'
do
  grep -Fq -- "$init_surface" "$temporary_root/init-help.txt"
done
grep -Fq \
  'person, organization, engagement, project, customer, temporary, custom' \
  "$temporary_root/init-help.txt"

# Core v0.3 identifies an existing Folderbase only when both v0.3 markers
# are present. Keep this separate from the v0.5 manifest-only discovery proof.
v03_boundary_root="$temporary_root/v03-boundary"
mkdir -p "$v03_boundary_root"
v03_boundary_arguments=(
  "$v03_boundary_root"
  --name 'Core v0.3 boundary contract'
  --kind project
  --no-agent-adapters
  --json
)
"$folderbase" init \
  "${v03_boundary_arguments[@]:0:1}" \
  --dry-run \
  "${v03_boundary_arguments[@]:1}" \
  >"$temporary_root/v03-boundary-preview.json"
v03_boundary_digest=$(
  read_plan_digest "$temporary_root/v03-boundary-preview.json"
)
"$folderbase" init \
  "${v03_boundary_arguments[@]:0:1}" \
  --expected-plan-digest "$v03_boundary_digest" \
  "${v03_boundary_arguments[@]:1}" \
  >"$temporary_root/v03-boundary-init.json"
test -f "$v03_boundary_root/FOLDERBASE.md"
test -f "$v03_boundary_root/.folderbase/manifest.json"
"$folderbase" validate "$v03_boundary_root" --json \
  >"$temporary_root/v03-boundary-valid.json"

mv \
  "$v03_boundary_root/FOLDERBASE.md" \
  "$temporary_root/v03-boundary-entry.saved"
if "$folderbase" validate "$v03_boundary_root" --json \
  >"$temporary_root/v03-boundary-missing-entry.json"
then
  printf '%s\n' \
    'Core v0.3 unexpectedly accepted a boundary without FOLDERBASE.md.' >&2
  exit 1
fi
python3 - "$temporary_root/v03-boundary-missing-entry.json" <<'PY'
import json
import sys

report = json.load(open(sys.argv[1], encoding="utf-8"))
assert report["valid"] is False
assert "missing_folderbase_entry" in {
    finding["code"] for finding in report["findings"]
}
PY
mv \
  "$temporary_root/v03-boundary-entry.saved" \
  "$v03_boundary_root/FOLDERBASE.md"

mv \
  "$v03_boundary_root/.folderbase/manifest.json" \
  "$temporary_root/v03-boundary-manifest.saved"
if "$folderbase" validate "$v03_boundary_root" --json \
  >"$temporary_root/v03-boundary-missing-manifest.json"
then
  printf '%s\n' \
    'Core v0.3 unexpectedly accepted a boundary without its manifest.' >&2
  exit 1
fi
python3 - "$temporary_root/v03-boundary-missing-manifest.json" <<'PY'
import json
import sys

report = json.load(open(sys.argv[1], encoding="utf-8"))
assert report["valid"] is False
assert "missing_manifest" in {
    finding["code"] for finding in report["findings"]
}
PY
mv \
  "$temporary_root/v03-boundary-manifest.saved" \
  "$v03_boundary_root/.folderbase/manifest.json"
"$folderbase" validate "$v03_boundary_root" --json \
  >"$temporary_root/v03-boundary-restored.json"

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
  approved_plan_digest=$(
    read_plan_digest "$temporary_root/template-$template_slug-dry-run.json"
  )
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

  "$folderbase" init \
    "${template_arguments[@]:0:1}" \
    --expected-plan-digest "$approved_plan_digest" \
    "${template_arguments[@]:1}" \
    >"$temporary_root/template-$template_slug-init.json"
  "$folderbase" validate "$template_workspace" --json \
    >"$temporary_root/template-$template_slug-validate.json"
  python3 - \
    "$template_workspace/.folderbase/manifest.json" \
    "$temporary_root/template-$template_slug-validate.json" \
    "$temporary_root/template-$template_slug-init.json" \
    "$template_selector" \
    "$manifest_kind" \
    "$preserved_template_path" \
    "$approved_plan_digest" <<'PY'
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
assert result["applied_plan_digest"] == {
    "algorithm": "sha256",
    "digest": sys.argv[7],
}
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

stale_workspace="$temporary_root/stale-plan"
mkdir -p "$stale_workspace"
stale_arguments=(
  "$stale_workspace"
  --name 'Stale plan'
  --kind project
  --template folderbase.project@0.2.2
  --answer 'purpose=Refuse unreviewed membership changes.'
  --answer 'current_state=The preview begins from an empty folder.'
  --answer 'next_action=Apply only the exact reviewed plan.'
  --json
)
"$folderbase" init \
  "${stale_arguments[@]:0:1}" \
  --dry-run \
  "${stale_arguments[@]:1}" \
  >"$temporary_root/stale-plan-preview.json"
stale_digest=$(read_plan_digest "$temporary_root/stale-plan-preview.json")
printf '%s\n' 'added after preview' >"$stale_workspace/unreviewed.txt"
snapshot_workspace \
  "$stale_workspace" \
  "$temporary_root/stale-plan-before.json"
if "$folderbase" init \
  "${stale_arguments[@]:0:1}" \
  --expected-plan-digest "$stale_digest" \
  "${stale_arguments[@]:1}" \
  >"$temporary_root/stale-plan-apply.json" \
  2>"$temporary_root/stale-plan-apply.err"
then
  printf '%s\n' 'A stale initialization plan unexpectedly applied.' >&2
  exit 1
fi
test ! -s "$temporary_root/stale-plan-apply.json"
assert_json_error_code \
  "$temporary_root/stale-plan-apply.err" \
  initialization_plan_changed
snapshot_workspace \
  "$stale_workspace" \
  "$temporary_root/stale-plan-after.json"
cmp \
  "$temporary_root/stale-plan-before.json" \
  "$temporary_root/stale-plan-after.json"

changed_request_workspace="$temporary_root/changed-request"
mkdir -p "$changed_request_workspace"
changed_request_arguments=(
  "$changed_request_workspace"
  --name 'Approved name'
  --kind project
  --template folderbase.project@0.2.2
  --answer 'purpose=Bind the complete request.'
  --answer 'current_state=The approved request has one exact name.'
  --answer 'next_action=Reject a changed request.'
  --json
)
"$folderbase" init \
  "${changed_request_arguments[@]:0:1}" \
  --dry-run \
  "${changed_request_arguments[@]:1}" \
  >"$temporary_root/changed-request-preview.json"
changed_request_digest=$(
  read_plan_digest "$temporary_root/changed-request-preview.json"
)
snapshot_workspace \
  "$changed_request_workspace" \
  "$temporary_root/changed-request-before.json"
if "$folderbase" init \
  "$changed_request_workspace" \
  --name 'Different name' \
  --kind project \
  --template folderbase.project@0.2.2 \
  --answer 'purpose=Bind the complete request.' \
  --answer 'current_state=The approved request has one exact name.' \
  --answer 'next_action=Reject a changed request.' \
  --expected-plan-digest "$changed_request_digest" \
  --json \
  >"$temporary_root/changed-request-apply.json" \
  2>"$temporary_root/changed-request-apply.err"
then
  printf '%s\n' 'A changed initialization request unexpectedly applied.' >&2
  exit 1
fi
test ! -s "$temporary_root/changed-request-apply.json"
assert_json_error_code \
  "$temporary_root/changed-request-apply.err" \
  initialization_plan_changed
snapshot_workspace \
  "$changed_request_workspace" \
  "$temporary_root/changed-request-after.json"
cmp \
  "$temporary_root/changed-request-before.json" \
  "$temporary_root/changed-request-after.json"

replaced_root="$temporary_root/replaced-root"
original_root="$temporary_root/replaced-root-original"
mkdir -p "$replaced_root"
printf '%s\n' 'visible bytes stay identical' >"$replaced_root/visible.txt"
replaced_root_arguments=(
  "$replaced_root"
  --name 'Physical root identity'
  --kind project
  --template folderbase.project@0.2.2
  --answer 'purpose=Bind one physical directory.'
  --answer 'current_state=The selected root may be replaced at the same path.'
  --answer 'next_action=Reject the replacement.'
  --json
)
"$folderbase" init \
  "${replaced_root_arguments[@]:0:1}" \
  --dry-run \
  "${replaced_root_arguments[@]:1}" \
  >"$temporary_root/replaced-root-preview.json"
replaced_root_digest=$(
  read_plan_digest "$temporary_root/replaced-root-preview.json"
)
mv "$replaced_root" "$original_root"
mkdir -p "$replaced_root"
printf '%s\n' 'visible bytes stay identical' >"$replaced_root/visible.txt"
snapshot_workspace \
  "$replaced_root" \
  "$temporary_root/replaced-root-before.json"
if "$folderbase" init \
  "${replaced_root_arguments[@]:0:1}" \
  --expected-plan-digest "$replaced_root_digest" \
  "${replaced_root_arguments[@]:1}" \
  >"$temporary_root/replaced-root-apply.json" \
  2>"$temporary_root/replaced-root-apply.err"
then
  printf '%s\n' 'A same-path replacement root unexpectedly initialized.' >&2
  exit 1
fi
test ! -s "$temporary_root/replaced-root-apply.json"
assert_json_error_code \
  "$temporary_root/replaced-root-apply.err" \
  initialization_plan_changed
snapshot_workspace \
  "$replaced_root" \
  "$temporary_root/replaced-root-after.json"
cmp \
  "$temporary_root/replaced-root-before.json" \
  "$temporary_root/replaced-root-after.json"
test "$(cat "$original_root/visible.txt")" = 'visible bytes stay identical'

for rejected_digest in malformed "$(printf 'e%.0s' {1..64})"
do
  digest_workspace="$temporary_root/rejected-digest-$rejected_digest"
  mkdir -p "$digest_workspace"
  digest_arguments=(
    "$digest_workspace"
    --name 'Rejected digest'
    --kind project
    --template folderbase.project@0.2.2
    --answer 'purpose=Reject an unapproved digest.'
    --answer 'current_state=The supplied digest is not the preview identity.'
    --answer 'next_action=Leave the folder unchanged.'
    --json
  )
  snapshot_workspace \
    "$digest_workspace" \
    "$temporary_root/rejected-digest-$rejected_digest-before.json"
  if "$folderbase" init \
    "${digest_arguments[@]:0:1}" \
    --expected-plan-digest "$rejected_digest" \
    "${digest_arguments[@]:1}" \
    >"$temporary_root/rejected-digest-apply.json" \
    2>"$temporary_root/rejected-digest-apply.err"
  then
    printf 'A rejected initialization digest unexpectedly applied: %s\n' \
      "$rejected_digest" >&2
    exit 1
  fi
  test ! -s "$temporary_root/rejected-digest-apply.json"
  if [[ "$rejected_digest" = malformed ]]; then
    rejected_digest_error=invalid_initialization_plan_digest
  else
    rejected_digest_error=initialization_plan_changed
  fi
  assert_json_error_code \
    "$temporary_root/rejected-digest-apply.err" \
    "$rejected_digest_error"
  snapshot_workspace \
    "$digest_workspace" \
    "$temporary_root/rejected-digest-$rejected_digest-after.json"
  cmp \
    "$temporary_root/rejected-digest-$rejected_digest-before.json" \
    "$temporary_root/rejected-digest-$rejected_digest-after.json"
done

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
no_adapter_digest=$(
  read_plan_digest "$temporary_root/no-agent-adapters-dry-run.json"
)
snapshot_workspace \
  "$no_adapter_workspace" \
  "$temporary_root/no-agent-adapters-before-toggle.json"
if "$folderbase" init \
  "$no_adapter_workspace" \
  --name 'No agent adapters' \
  --kind custom \
  --template folderbase.custom@0.2.0 \
  --answer 'purpose=Initialize without creating or changing agent adapters.' \
  --answer 'current_state=Existing adapter files belong to the user.' \
  --answer 'next_action=Preserve both adapter files.' \
  --expected-plan-digest "$no_adapter_digest" \
  --json \
  >"$temporary_root/no-agent-adapters-toggle.json" \
  2>"$temporary_root/no-agent-adapters-toggle.err"
then
  printf '%s\n' 'A changed adapter choice unexpectedly applied.' >&2
  exit 1
fi
test ! -s "$temporary_root/no-agent-adapters-toggle.json"
assert_json_error_code \
  "$temporary_root/no-agent-adapters-toggle.err" \
  initialization_plan_changed
snapshot_workspace \
  "$no_adapter_workspace" \
  "$temporary_root/no-agent-adapters-after-toggle.json"
cmp \
  "$temporary_root/no-agent-adapters-before-toggle.json" \
  "$temporary_root/no-agent-adapters-after-toggle.json"
"$folderbase" init \
  "${no_adapter_arguments[@]:0:1}" \
  --expected-plan-digest "$no_adapter_digest" \
  "${no_adapter_arguments[@]:1}" \
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
assert result["applied_plan_digest"] == preview["plan_digest"]
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
workspace_digest=$(read_plan_digest "$temporary_root/dry-run.json")
test ! -e "$workspace/.folderbase"
test ! -e "$workspace/FOLDERBASE.md"
test "$(sed -n '1p' "$workspace/note.md")" = alpha

"$folderbase" init \
  "$workspace" \
  --expected-plan-digest "$workspace_digest" \
  --json >"$temporary_root/init.json"
"$folderbase" validate "$workspace" --json >"$temporary_root/validate.json"
"$folderbase" attest "$workspace" --json >"$temporary_root/attest-first.json"
"$folderbase" attest "$workspace" --json >"$temporary_root/attest-second.json"
python3 - \
  "$temporary_root/dry-run.json" \
  "$temporary_root/init.json" \
  "$temporary_root/validate.json" \
  "$temporary_root/attest-first.json" \
  "$temporary_root/attest-second.json" \
  "$workspace" <<'PY'
import json
import hashlib
import os
import re
import sys

preview = json.load(open(sys.argv[1], encoding="utf-8"))
result = json.load(open(sys.argv[2], encoding="utf-8"))
validation = json.load(open(sys.argv[3], encoding="utf-8"))
first_attestation = json.load(open(sys.argv[4], encoding="utf-8"))
second_attestation = json.load(open(sys.argv[5], encoding="utf-8"))
manifest_bytes = open(
    os.path.join(sys.argv[6], ".folderbase", "manifest.json"), "rb"
).read()
manifest = json.loads(manifest_bytes)
assert result["applied_plan_digest"] == preview["plan_digest"]
assert validation["valid"] is True
assert first_attestation == second_attestation
assert set(first_attestation) == {
    "root",
    "folderbase_id",
    "protocol_version",
    "manifest_sha256",
    "root_instance_sha256",
}
assert os.path.isabs(first_attestation["root"])
assert os.path.realpath(first_attestation["root"]) == os.path.realpath(sys.argv[6])
assert first_attestation["folderbase_id"] == result["folderbase_id"]
assert first_attestation["folderbase_id"] == manifest["folderbase"]["id"]
assert first_attestation["protocol_version"] == manifest["protocol_version"]
assert first_attestation["manifest_sha256"] == hashlib.sha256(manifest_bytes).hexdigest()
assert re.fullmatch(r"[0-9a-f]{64}", first_attestation["root_instance_sha256"])
PY

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
adversarial_digest=$(
  read_plan_digest "$temporary_root/adversarial-dry-run.json"
)

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

"$folderbase" init \
  "$adversarial_workspace" \
  --expected-plan-digest "$adversarial_digest" \
  --json \
  >"$temporary_root/adversarial-init.json"
"$folderbase" workspace list "$adversarial_workspace" --json \
  >"$temporary_root/adversarial-list.json"
python3 - \
  "$temporary_root/adversarial-dry-run.json" \
  "$temporary_root/adversarial-init.json" \
  "$temporary_root/adversarial-list.json" <<'PY'
import json
import sys

preview = json.load(open(sys.argv[1], encoding="utf-8"))
result = json.load(open(sys.argv[2], encoding="utf-8"))
entries = json.load(open(sys.argv[3], encoding="utf-8"))["entries"]
by_path = {entry["path"]: entry for entry in entries}
assert result["applied_plan_digest"] == preview["plan_digest"]
assert by_path["escape.txt"]["kind"] == "symlink"
assert by_path["escape.txt"]["editable"] is False
PY

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
template_digest=$(read_plan_digest "$temporary_root/template-dry-run.json")
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

"$folderbase" init \
  "${template_args[@]:0:1}" \
  --expected-plan-digest "$template_digest" \
  "${template_args[@]:1}" \
  >"$temporary_root/template-init.json"
test ! -e "$template_file_sentinel"
test ! -e "$template_process_sentinel"
python3 - \
  "$temporary_root/template-dry-run.json" \
  "$temporary_root/template-init.json" \
  "$template_workspace/FOLDERBASE.md" \
  "$template_prompt" \
  "$template_recursive" <<'PY'
import json
import sys

preview = json.load(open(sys.argv[1], encoding="utf-8"))
result = json.load(open(sys.argv[2], encoding="utf-8"))
actual = open(sys.argv[3], "rb").read()
expected = (
    f"## Purpose\n{sys.argv[4]}\n\n"
    f"## Current state\n{sys.argv[5]}\n\n"
).encode("utf-8")
assert result["applied_plan_digest"] == preview["plan_digest"]
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
