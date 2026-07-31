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
CORE_V05_FIXTURE_PROVENANCE_RED_EXIT=1
```

## Fixture provenance

The checked-in manifest was captured from the CLI installed directly from the
exact candidate commit with this procedure:

```sh
tool_root=$(mktemp -d)
fixture_root=$(mktemp -d)/folderbase-v05-manifest.raD9cc
mkdir -p "$fixture_root"
cargo install --git https://github.com/chalkagents/folderbase.git \
  --rev 45de7804bb4e57224e5b9495e4394441ce652f0b \
  --locked \
  --root "$tool_root" \
  folderbase-cli
"$tool_root/bin/folderbase" init "$fixture_root" --json
cp "$fixture_root/.folderbase/manifest.json" \
  tests/fixtures/core-v05-manifest-only.json
shasum -a 256 tests/fixtures/core-v05-manifest-only.json
```

The ID, generated name, and timestamp are intentionally frozen captured
values, not deterministic regeneration inputs. The immutable fixture digest
is:

```text
200abe55ae436695c2a0cb8b57e3c942733db5b85770d396261cf6618f581e92
```

The contract recomputes and asserts this digest before using the fixture.

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

The v0.5 test installs its CLI from the exact commit itself and rejects a
caller-supplied executable override. A recording wrapper observes every CLI
invocation and asserts the complete sequence, proving the candidate path uses
only version, list, validate, and conditional attest operations in that order.

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
