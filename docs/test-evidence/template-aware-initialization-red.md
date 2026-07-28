# Template-aware initialization RED evidence

This records the failing side of the red-green cycles for template-aware agent
guidance. The branch contains only green tests; the REDs were captured before
the skill or compatibility reference was changed.

## Fixed seams and baseline

- Installed-guidance seam: `tests/acceptance.sh`
- Immutable public CLI seam: `tests/core-contract.sh`
- Skills baseline: `27e365a6523e3005e0f07bb0e3f6a864de396993`
- Exact Core: `2daf6968387e8c8111dfa03a922ed8866c015e15`
  (`folderbase 0.1.0`)

The acceptance seam specifies what an installed agent is taught. The Core
integration seam invokes the real released CLI and observes its help,
initialization preview, application, validation, and preserved ordinary files.
It does not mock Folderbase internals.

## RED 1: installed guidance did not expose template-aware decisions

Before changing `SKILL.md` or its reference, the acceptance test required:

- `folderbase init --help` discovery;
- the phrase `consequential unanswered`;
- the phrase `guidance, not a rigid taxonomy`; and
- every exact built-in template selector from the immutable release.

Run:

```bash
set +e
bash tests/acceptance.sh
red_exit=$?
set -e
printf 'ACCEPTANCE_RED_EXIT=%s\n' "$red_exit"
```

Captured result:

```text
ACCEPTANCE_RED_EXIT=1
```

The check failed without stdout because the prior skill had only a generic
untemplated initialization command and the prior compatibility reference did
not enumerate the exact selector and question surface.

## RED 2: immutable Core coverage lacked the selector contract

Before the compatibility reference was changed, the Core integration test
required all exact shipped selectors to exist in that reference, then exercised
the real CLI help and each current starter.

Run with a locally built binary from the exact Core commit:

```bash
set +e
FOLDERBASE_CLI_BIN=/absolute/path/to/exact-v0.1.0/folderbase \
  bash tests/core-contract.sh
red_exit=$?
set -e
printf 'CORE_CONTRACT_RED_EXIT=%s\n' "$red_exit"
```

Captured result:

```text
CORE_CONTRACT_RED_EXIT=1
```

The first missing exact selector stopped the contract before any mutation.

## Compatibility finding during the green cycle

An initial integration loop applied every package present in the release.
`folderbase.project@0.2.1` initialized successfully but the immediately
following `folderbase validate --json` returned `valid: false` because its
rendered `FOLDERBASE.md` lacks the required `Navigate`, `Operating rules`, and
`Unresolved work` sections.

The green contract therefore:

- previews project 0.2.1 read-only to prove it is discoverable;
- explicitly prevents the skill from applying it;
- uses project 0.2.2 for new project initialization; and
- applies and validates all seven current starter kinds, including safe custom
  answer handling, against the immutable CLI.

No newer Core behavior or unpublished template command was substituted.

## GREEN

After implementing the template decision table, minimal-question contract,
argv-safe typed answers, additive preview/approval workflow, and exact
compatibility matrix:

```text
Folderbase skill acceptance contract is clean.
Folderbase skill and immutable Core contract are compatible.
NARROW_TEMPLATE_GREEN=1
```
