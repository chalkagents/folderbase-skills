# Template-aware initialization RED evidence

This records two independently reproducible failing tests for template-aware
agent guidance. Each reproduction starts from the fixed pre-feature baseline,
applies only its test change in an isolated detached worktree, and removes that
worktree afterward. The feature branch contains only the subsequent green
tests and implementation.

## Fixed seams and baseline

- Installed-guidance seam: `tests/acceptance.sh`
- Immutable public CLI seam: `tests/core-contract.sh`
- Skills baseline: `27e365a6523e3005e0f07bb0e3f6a864de396993`
- Exact Core: `2daf6968387e8c8111dfa03a922ed8866c015e15`
  (`folderbase 0.1.0`)

The acceptance seam specifies what an installed agent is taught. The Core
integration seam invokes the real released CLI for its green behavior suite;
the RED below fails on the missing compatibility declaration before installing
or mutating anything. Neither seam mocks Folderbase internals.

## RED 1: installed guidance lacked the decision contract

Run from any clean checkout of this repository:

```bash
acceptance_source=$(git rev-parse --show-toplevel)
acceptance_red_root=$(mktemp -d)
git -C "$acceptance_source" worktree add --detach \
  "$acceptance_red_root/repository" \
  27e365a6523e3005e0f07bb0e3f6a864de396993
cd "$acceptance_red_root/repository"

git apply <<'PATCH'
diff --git a/tests/acceptance.sh b/tests/acceptance.sh
--- a/tests/acceptance.sh
+++ b/tests/acceptance.sh
@@ -111,6 +111,8 @@ for required_text in \
   'symlink' \
   'secret' \
   'never execute' \
+  'consequential unanswered' \
+  'guidance, not a rigid taxonomy' \
   'prompt-shaped' \
   'secret-shaped path names' \
   'source changed after planning'
PATCH

set +e
bash tests/acceptance.sh
acceptance_red_exit=$?
set -e
printf 'ACCEPTANCE_RED_EXIT=%s\n' "$acceptance_red_exit"

cd "$acceptance_source"
git -C "$acceptance_source" worktree remove --force \
  "$acceptance_red_root/repository"
rm -R "$acceptance_red_root"
```

Captured result:

```text
ACCEPTANCE_RED_EXIT=1
```

The baseline skill had only a generic initialization command. It did not teach
the user-intent choice or the minimal consequential-question contract.

## RED 2: compatibility guidance lacked exact built-in selectors

Run independently from any clean checkout:

```bash
core_source=$(git rev-parse --show-toplevel)
core_red_root=$(mktemp -d)
git -C "$core_source" worktree add --detach \
  "$core_red_root/repository" \
  27e365a6523e3005e0f07bb0e3f6a864de396993
cd "$core_red_root/repository"

git apply --unidiff-zero <<'PATCH'
diff --git a/tests/core-contract.sh b/tests/core-contract.sh
--- a/tests/core-contract.sh
+++ b/tests/core-contract.sh
@@ -12,0 +13,14 @@
+protocol_reference="$test_directory/../skills/work-with-folderbase/references/protocol-surface.md"
+for template_selector in \
+  'folderbase.person@0.2.0' \
+  'folderbase.organization@0.2.0' \
+  'folderbase.customer@0.2.0' \
+  'folderbase.engagement@0.2.0' \
+  'folderbase.project@0.2.1' \
+  'folderbase.project@0.2.2' \
+  'folderbase.temporary@0.2.0' \
+  'folderbase.custom@0.2.0'
+do
+  grep -Fq -- "$template_selector" "$protocol_reference"
+done
+
PATCH

set +e
bash tests/core-contract.sh
core_contract_red_exit=$?
set -e
printf 'CORE_CONTRACT_RED_EXIT=%s\n' "$core_contract_red_exit"

cd "$core_source"
git -C "$core_source" worktree remove --force \
  "$core_red_root/repository"
rm -R "$core_red_root"
```

Captured result:

```text
CORE_CONTRACT_RED_EXIT=1
```

The first exact selector was absent from the baseline compatibility reference,
so the test stopped before the Core install or any workspace mutation.

## Compatibility finding during the green cycle

An initial integration loop applied every package present in the release.
`folderbase.project@0.2.1` initialized successfully but the immediately
following `folderbase validate --json` returned `valid: false` because its
rendered `FOLDERBASE.md` lacks the required `Navigate`, `Operating rules`, and
`Unresolved work` sections.

The green contract therefore:

- previews project 0.2.1 read-only to prove it is discoverable;
- explicitly prevents the skill from applying it;
- uses project 0.2.2 for new project initialization;
- applies and validates all seven current starter kinds;
- verifies a real preserved template target and both adapter modes; and
- proves command-shaped multiline custom answers render literally without
  executing their file or process-shaped payloads.

No newer Core behavior or unpublished template command was substituted.

## GREEN

After implementing the shared selector fixture, template decision table,
minimal-question contract, argv-safe typed answers, additive
preview/approval workflow, and exact compatibility matrix:

```text
Folderbase skill acceptance contract is clean.
Folderbase skill and immutable Core contract are compatible.
```
