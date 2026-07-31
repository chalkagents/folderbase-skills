# Core 0.5 skill compatibility plan

## Scope

Adopt the published Core `v0.5.0-rc.1` read-only discovery contract at the existing public seams:

- `skills/work-with-folderbase/SKILL.md`
- `skills/work-with-folderbase/references/protocol-surface.md`
- `tests/acceptance.sh`, `tests/core-contract.sh`, and `tests/distribution.sh`

The skill will recognize `.folderbase/manifest.json` as the sole Folderbase boundary marker, accept manifest-only Folderbases, treat `FOLDERBASE.md` and `.folderbaseignore` as optional ordinary non-authoritative files, and inspect unmanaged folders metadata-first without initializing them.

## Test-first sequence

1. Add acceptance assertions that fail against the mandatory-two-marker and read-narrative-first guidance; make the minimum skill and reference edits to pass.
2. Add a narrow Core candidate contract that fails without an explicitly identified `v0.5.0-rc.1` CLI and proves ordinary listing, typed `missing_manifest`, read-only validation and attestation of a checked-in Core-generated manifest-only fixture, optional narrative absence, and sparse large-file metadata; make only consumer-side fixes needed to pass. Do not invoke candidate mutation to construct the read-only proof.
3. Run acceptance, public-eclipse, Skills reference validation, local plus pinned-v0.3 distribution, the v0.3 mutation contract with explicit two-marker assertions, and the configured Core 0.5 candidate contract.

## Non-goals

Do not change the v0.3 public install default or immutable publication evidence, publish a release, add mutating RC guidance, define Platform share/connect/remote commands, or modify Folderbase Core.
