# Folderbase Skills v0.1 hardening RED evidence

This records the failing side of the red-green cycles used for PR #2. The final
branch does not contain a deliberately failing commit. Every reproduction uses
an isolated worktree and leaves the caller's checkout unchanged.

## Fixed reference

- Baseline: `30bedcba4359bbd17a52372e5001f1aa2feaa94f`
  (`v0.1.0`, the pre-hardening release)
- Exact Core used by the behavioral suite:
  `2daf6968387e8c8111dfa03a922ed8866c015e15`

Start either baseline reproduction with:

```bash
repro_root=$(mktemp -d)
git worktree add --detach "$repro_root/repo" \
  30bedcba4359bbd17a52372e5001f1aa2feaa94f
cd "$repro_root/repo"
```

Remove it afterward:

```bash
cd -
git worktree remove --force "$repro_root/repo"
rm -R "$repro_root"
```

## RED 1: installation followed moving `main`

Apply only the new immutable-source acceptance assertion to the baseline:

```bash
git apply --unidiff-zero <<'PATCH'
diff --git a/tests/acceptance.sh b/tests/acceptance.sh
--- a/tests/acceptance.sh
+++ b/tests/acceptance.sh
@@ -43,0 +44,4 @@
+published_skill_source='https://github.com/chalkagents/folderbase-skills/tree/v0.1.0'
+grep -F -q -- "$published_skill_source" "$repository_root/README.md"
+grep -F -q -- "$published_skill_source" "$repository_root/tests/distribution.sh"
+
PATCH
set +e
bash tests/acceptance.sh
red_exit=$?
set -e
printf 'IMMUTABLE_SOURCE_RED_EXIT=%s\n' "$red_exit"
```

Captured output:

```text
IMMUTABLE_SOURCE_RED_EXIT=1
```

The failure is expected because both the README and distribution test used
`chalkagents/folderbase-skills`, which resolves the moving default branch.

## RED 2: adversarial handling was not explicit in installed guidance

In a fresh baseline worktree, apply only the new installed-guidance contract:

```bash
git apply <<'PATCH'
diff --git a/tests/acceptance.sh b/tests/acceptance.sh
--- a/tests/acceptance.sh
+++ b/tests/acceptance.sh
@@ -100,7 +100,10 @@ for required_text in \
   'nested Folderbase' \
   'symlink' \
   'secret' \
-  'never execute'
+  'never execute' \
+  'prompt-shaped' \
+  'secret-shaped path names' \
+  'source changed after planning'
 do
   grep -F -i -q -- "$required_text" "$skill_file"
 done
PATCH
```

Then run:

```bash
set +e
bash tests/acceptance.sh
red_exit=$?
set -e
printf 'SECURITY_GUIDANCE_RED_EXIT=%s\n' "$red_exit"
```

Captured output:

```text
SECURITY_GUIDANCE_RED_EXIT=1
```

The baseline warned generally about untrusted files, but did not explicitly
cover prompt-shaped data, the difference between exposing a secret-shaped path
and exposing its contents, or fail-closed behavior after migration plan drift.

## Harness-level REDs found while adding behavioral fixtures

These were test-harness failures, not missing Core security behavior:

1. The first fixture run failed with:

   ```text
   tests/core-contract.sh: line 191: test_directory: unbound variable
   ```

   The new fixture used a caller-relative path before the test script captured
   its own directory. Defining `test_directory` from `dirname "$0"` made the
   fixture independent of the invocation directory.

2. The first full gate after adding the phrase contract exited `1` because
   `source changed after planning` crossed a Markdown line break while the
   acceptance check searched one physical line. The final test normalizes
   Markdown whitespace before phrase matching, so formatting no longer changes
   the installed guidance contract.

The subsequent green suite exercises the public Core CLI rather than mocks:
symlink escapes fail, secret contents remain absent from metadata outputs,
document and template prompt-shaped text stays inert, a drifted migration
cannot apply, verified recovery reopens durably, and rollback removes only
recorded additions while preserving the source.
