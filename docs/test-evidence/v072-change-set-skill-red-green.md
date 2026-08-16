# Exact Core v0.7.2 Change Set skill evidence

Date: 2026-08-16

Branch: `codex/organization-change-set-skill`

Tracking: [folderbase-skills#14](https://github.com/chalkagents/folderbase-skills/issues/14)

## RED

The acceptance contract first required the exact v0.7.2 profile, stable
capability discovery, one-question HITL organization guidance, before/after
tree rationale, all-file-type handling, and a strict propose-only handoff. The
existing skill had none of that guidance.

```text
bash tests/acceptance.sh
CHANGE_SET_SKILL_ACCEPTANCE_RED_EXIT=1
```

No production skill or reference text was changed before this failure was
observed.

## GREEN

The single `work-with-folderbase` skill now supports one narrow exact Core
profile without changing the published v0.3 initialization pairing. A working
agent receives an already-authorized ordinary checkout, asks only consequential
organization questions, preserves every file type, and returns Core's immutable
Change Set plus staging to a separate reviewer.

The exact-source contract installs Folderbase Core from immutable commit
`7439babec74242d9d162ab09f12f2f1b1b2c5cbe`, verifies `folderbase 0.7.2` and
stable `folderbase.change-set@0.1.0`, and then proves:

- one authorized `shared` projection excludes a private sibling;
- Markdown, opaque binary, and 4 MiB media-shaped bytes remain ordinary files;
- agent edits produce `folderbase-change-set-v1` and provider-neutral staging;
- neither returned artifact contains the private sibling marker;
- a separate read-only assessment returns `clean`; and
- assessment does not modify either the shared source or private sibling.

```text
FOLDERBASE_CORE_CONTRACT=v0.7.2-change-set \
FOLDERBASE_CORE_REF=7439babec74242d9d162ab09f12f2f1b1b2c5cbe \
  bash tests/core-contract.sh

Folderbase skill and exact Core 0.7.2 Change Set handoff are compatible.
CHANGE_SET_CORE_GREEN_EXIT=0
```

## Verification gates

The completed slice also passes the portable skill and repository gates:

```text
bash -n tests/acceptance.sh tests/core-contract.sh
bash tests/acceptance.sh
python3 /Users/jerel/.codex/skills/.system/skill-creator/scripts/quick_validate.py \
  skills/work-with-folderbase
./node_modules/.bin/skills-ref validate skills/work-with-folderbase
git diff --check
```

Observed results:

```text
Folderbase skill acceptance contract is clean.
Skill is valid!
Valid skill: skills/work-with-folderbase
```

## Boundaries

This evidence does not claim App checkout creation, Live Folder transport,
Cloud authorization, synchronization, Keep Local, Archive, Cloud Agent VM
lifecycle, format-specific merging, or automated apply. The working agent does
not apply its own proposal; read-only assessment is not approval.
