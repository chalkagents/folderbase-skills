#!/usr/bin/env bash

set -euo pipefail

expected_os=${FOLDERBASE_EXPECT_OS:-$(uname -s)}
actual_os=$(uname -s)
if [[ "$actual_os" != "$expected_os" ]]; then
  printf 'Expected bootstrap host %s, received %s.\n' \
    "$expected_os" "$actual_os" >&2
  exit 1
fi

temporary_root=$(mktemp -d)
trap 'rm -R -- "$temporary_root"' EXIT

export HOME="$temporary_root/home"
export XDG_CACHE_HOME="$temporary_root/xdg-cache"
export XDG_CONFIG_HOME="$temporary_root/xdg-config"
export XDG_DATA_HOME="$temporary_root/xdg-data"
export npm_config_cache="$temporary_root/npm-cache"
export DISABLE_TELEMETRY=1
mkdir -p \
  "$HOME" \
  "$XDG_CACHE_HOME" \
  "$XDG_CONFIG_HOME" \
  "$XDG_DATA_HOME" \
  "$npm_config_cache"

skills_source='https://github.com/chalkagents/folderbase-skills/tree/v0.4.0'
skills_hash='6bff7b1dd04b7aae5b361a2be773a6cfa4d9fde8c98578638abce76821a93f5a'
skill_sha256='82b871a5d9125b58c91481e7c9c115ea539939ece67f978ca7ed35f64b2af4a3'
reference_sha256='543cfb24febe388a3833999dcd781c83caf12ef14ca59c1cb4cc93964bf78792'
core_package='@folderbase/cli@0.7.2'
core_integrity='sha512-fK5g/C8X2rgoa1rWp4PUdpuFZZ7tlJGbv54olhgVAamlBUA6EQElzIcvap0oGd7k3HctvvnhuItw0/rIxm6/tg=='

node - <<'JS'
const [major, minor] = process.versions.node.split(".").map(Number);
if (major < 22 || (major === 22 && minor < 20)) {
  throw new Error("Folderbase Skills requires Node.js 22.20 or newer.");
}
JS

test "$(npm view "$core_package" version)" = '0.7.2'
test "$(npm view "$core_package" dist.integrity)" = "$core_integrity"
test "$(npx --yes "$core_package" --version)" = 'folderbase 0.7.2'

discovery_output=$(npx --yes skills@1.5.20 add "$skills_source" --list)
grep -F -q -- 'work-with-folderbase' <<<"$discovery_output"

project_root="$temporary_root/agent-project"
mkdir -p "$project_root"
git -C "$project_root" init --quiet
(
  cd "$project_root"
  npx --yes skills@1.5.20 add \
    "$skills_source" \
    --agent codex \
    --skill work-with-folderbase \
    --copy \
    --yes
)

installed_skill="$project_root/.agents/skills/work-with-folderbase"
test -f "$installed_skill/SKILL.md"
test -f "$installed_skill/references/protocol-surface.md"
test -f "$project_root/skills-lock.json"
python3 - \
  "$project_root/skills-lock.json" \
  "$skills_hash" <<'PY'
import json
import sys

lock = json.load(open(sys.argv[1], encoding="utf-8"))
skill = lock["skills"]["work-with-folderbase"]
assert skill == {
    "source": "chalkagents/folderbase-skills",
    "sourceType": "github",
    "computedHash": sys.argv[2],
    "skillPath": "skills/work-with-folderbase/SKILL.md",
    "ref": "v0.4.0",
}
PY
test "$(sha256sum "$installed_skill/SKILL.md" | awk '{ print $1 }')" = \
  "$skill_sha256"
test "$(
  sha256sum "$installed_skill/references/protocol-surface.md" |
    awk '{ print $1 }'
)" = "$reference_sha256"

contract="$temporary_root/core-contract.json"
npx --yes "$core_package" protocol contract --json >"$contract"
python3 - "$contract" <<'PY'
import json
import sys

contract = json.load(open(sys.argv[1], encoding="utf-8"))
capabilities = {
    (item["name"], item["version"], item["stability"])
    for item in contract["capabilities"]
}
assert ("folderbase.change-set", "0.1.0", "stable") in capabilities
PY

source_root="$temporary_root/source-folderbase"
checkout_root="$temporary_root/authorized-checkout"
staging_root="$temporary_root/change-set-staging"
mkdir -p \
  "$source_root/workspace/repository" \
  "$source_root/private"
printf '%s\n' 'base project notes' >"$source_root/workspace/notes.md"
printf '%s\n' 'PRIVATE-SIBLING-MARKER' >"$source_root/private/owner-only.txt"
printf '%s\n' 'unknown ordinary bytes' \
  >"$source_root/workspace/archive.custom-format"
printf '%s\n' '%PDF-1.7 demo bytes' >"$source_root/workspace/brief.pdf"
printf '%s\n' 'fn main() {}' >"$source_root/workspace/repository/main.rs"
git -C "$source_root/workspace/repository" init --quiet
git -C "$source_root/workspace/repository" add main.rs
python3 - \
  "$source_root/workspace/sample.bin" \
  "$source_root/workspace/project.mp4" \
  "$source_root/workspace/project.sqlite" <<'PY'
from pathlib import Path
import sqlite3
import sys

Path(sys.argv[1]).write_bytes(b"\x00\x01\x02\x03")
with Path(sys.argv[2]).open("wb") as output:
    output.truncate(4 * 1024 * 1024)
connection = sqlite3.connect(sys.argv[3])
connection.execute("CREATE TABLE tasks (id INTEGER PRIMARY KEY, title TEXT)")
connection.execute("INSERT INTO tasks (title) VALUES (?)", ("ship bootstrap",))
connection.commit()
connection.close()
PY

npx --yes "$core_package" init "$source_root" --json \
  >"$temporary_root/init-result.json"
python3 - \
  "$source_root/.folderbase/manifest.json" \
  "$temporary_root/checkout-request.json" <<'PY'
import json
import sys

manifest = json.load(open(sys.argv[1], encoding="utf-8"))
request = {
    "format": "folderbase-checkout-request-v1",
    "folderbase_id": manifest["folderbase"]["id"],
    "projection_id": "projection_019f0000-0000-7000-8000-000000000019",
    "folder_scope_id": "folderscope_019f0000-0000-7000-8000-000000000019",
    "scope_revision_sha256": "1" * 64,
    "permission": "can_work",
    "authorized_paths": [{"path_prefix": "workspace"}],
}
json.dump(request, open(sys.argv[2], "w", encoding="utf-8"))
PY

npx --yes "$core_package" change-set checkout \
  "$source_root" "$checkout_root" --stdin --json \
  <"$temporary_root/checkout-request.json" \
  >"$temporary_root/checkout-result.json"

test -f "$checkout_root/.folderbase/checkout.json"
test ! -e "$checkout_root/.folderbase/manifest.json"
test ! -e "$checkout_root/private"
for authorized_path in \
  workspace/notes.md \
  workspace/sample.bin \
  workspace/project.mp4 \
  workspace/project.sqlite \
  workspace/brief.pdf \
  workspace/archive.custom-format \
  workspace/repository/main.rs \
  workspace/repository/.git/HEAD
do
  cmp "$source_root/$authorized_path" "$checkout_root/$authorized_path"
done

printf '%s\n' 'agent-organized project notes' \
  >"$checkout_root/workspace/notes.md"
printf '%s\n' 'fn main() { println!("organized"); }' \
  >"$checkout_root/workspace/repository/main.rs"
mkdir -p "$checkout_root/workspace/organized"
printf '%s\n' 'new agent context' \
  >"$checkout_root/workspace/organized/context.md"
python3 - "$checkout_root/workspace/project.sqlite" <<'PY'
import sqlite3
import sys

connection = sqlite3.connect(sys.argv[1])
connection.execute("INSERT INTO tasks (title) VALUES (?)", ("review change set",))
connection.commit()
connection.close()
PY

npx --yes "$core_package" change-set propose \
  "$checkout_root" "$staging_root" --json \
  >"$temporary_root/change-set.json"
test -f "$staging_root/index.json"

python3 - \
  "$temporary_root/checkout-result.json" \
  "$temporary_root/change-set.json" \
  "$checkout_root" \
  "$staging_root" <<'PY'
import json
from pathlib import Path
import re
import sys

checkout = json.load(open(sys.argv[1], encoding="utf-8"))
change_set = json.load(open(sys.argv[2], encoding="utf-8"))
assert checkout["format"] == "folderbase-checkout-result-v1"
assert change_set["format"] == "folderbase-change-set-v1"
assert change_set["payload"]["deltas"]
assert re.fullmatch(r"[0-9a-f]{64}", change_set["change_set_sha256"])

private_marker = b"PRIVATE-SIBLING-MARKER"
for root in (Path(sys.argv[3]), Path(sys.argv[4])):
    for path in root.rglob("*"):
        if path.is_file():
            assert private_marker not in path.read_bytes(), path
assert private_marker not in Path(sys.argv[2]).read_bytes()
PY

npx --yes "$core_package" change-set assess \
  "$source_root" "$staging_root" --stdin --json \
  <"$temporary_root/change-set.json" \
  >"$temporary_root/assessment.json"
python3 - \
  "$temporary_root/change-set.json" \
  "$temporary_root/assessment.json" <<'PY'
import json
import re
import sys

change_set = json.load(open(sys.argv[1], encoding="utf-8"))
assessment = json.load(open(sys.argv[2], encoding="utf-8"))
assert assessment["format"] == "folderbase-change-set-assessment-v1"
assert assessment["change_set_sha256"] == change_set["change_set_sha256"]
assert assessment["status"] == "clean"
assert assessment["conflicts"] == []
assert re.fullmatch(r"[0-9a-f]{64}", assessment["current_projection_sha256"])
PY

test "$(cat "$source_root/workspace/notes.md")" = 'base project notes'
test "$(cat "$source_root/private/owner-only.txt")" = \
  'PRIVATE-SIBLING-MARKER'

printf '%s\n' \
  "Public Skills v0.4.0 and Core CLI v0.7.2 bootstrap passed on $actual_os."
