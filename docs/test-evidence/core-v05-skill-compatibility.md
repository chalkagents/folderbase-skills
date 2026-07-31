# Core v0.5 skill compatibility evidence

This records the consumer-side compatibility proof for exact Folderbase Core
`v0.5.0-rc.1` at
`45de7804bb4e57224e5b9495e4394441ce652f0b`. It does not change the public
Skills `v0.3.0` release, the exact Core v0.3.0 mutation pin, or any Cloud
contract.

## Red and review findings

The first candidate guidance validated and attested before listing an ordinary
folder, created its read-only fixture by invoking candidate `init`, did not run
the new contract in CI, and did not distinguish the two version-specific root
rules. Independent specification and standards reviews therefore returned
no-go.

Acceptance was then extended with exact profile claims before the prose used
their canonical wording:

```text
CORE_V05_PROFILE_WORDING_RED_EXIT=1
```

## Green contract

The reviewed workflow now:

- detects `folderbase --version` before classifying protocol state;
- preserves the exact v0.3.0 mutation rule requiring both `FOLDERBASE.md` and
  `.folderbase/manifest.json`;
- gives exact v0.5.0-rc.1 a separate read-only profile whose sole boundary is
  `.folderbase/manifest.json`;
- lists ordinary metadata before validation, content reads, or attestation;
- attests only after successful manifest validation;
- validates a checked-in, Core-generated manifest fixture without invoking
  candidate mutation; and
- preserves metadata-first inspection of a sparse 10 GiB file.

The v0.3 contract dynamically removes each required marker in turn and proves
the typed `missing_folderbase_entry` and `missing_manifest` findings before
restoring a valid root.

Captured local results:

```text
ACCEPTANCE_GREEN_EXIT=0
PUBLIC_ECLIPSE_GREEN_EXIT=0
CI_POLICY_GREEN_EXIT=0
SKILLS_REF_GREEN_EXIT=0
CORE_V030_GREEN_EXIT=0
Folderbase skill and immutable Core contract are compatible.
CORE_V050_RC1_GREEN_EXIT=0
Folderbase skill and exact Core 0.5 candidate read-only contract are compatible.
DISTRIBUTION_GREEN_EXIT=0
Local and version-pinned published Folderbase skill installs are valid.
```

`tests/distribution.sh` exercised both this checkout and the unchanged public
`v0.3.0` install for Codex, Claude Code, Cursor, Hermes Agent, and OpenClaw.
CI runs both Core profiles separately and installs the v0.5 candidate from its
exact immutable commit.
