# Tested Folderbase protocol surface

This skill treats the public
[`chalkagents/folderbase`](https://github.com/chalkagents/folderbase) repository
as the only protocol authority. It does not copy schemas, templates, adapter
text, or implementation logic.

## Compatibility pin

- Verified release tag: `v0.1.0`
- Verified core commit:
  `2daf6968387e8c8111dfa03a922ed8866c015e15`
- Crate and CLI version: `0.1.0`
- Folderbase Protocol 0.1
- Folderbase manifest schema additions in Protocol 0.2
- Template Protocol 0.2

The `0.x` surface is pre-stable. Mutation requires this tested CLI line and
protocol range. An unsupported major or an untested `0.x` minor remains
read-only until this reference and the acceptance suite are updated.

## Authoritative documents

- [Protocol specification](https://github.com/chalkagents/folderbase/blob/2daf6968387e8c8111dfa03a922ed8866c015e15/docs/protocol-spec.md)
- [Template protocol](https://github.com/chalkagents/folderbase/blob/2daf6968387e8c8111dfa03a922ed8866c015e15/docs/template-protocol.md)
- [Schemas and conformance artifacts](https://github.com/chalkagents/folderbase/blob/2daf6968387e8c8111dfa03a922ed8866c015e15/protocol/README.md)

## Stable CLI operations

- `folderbase inspect`
- `folderbase init`
- `folderbase validate`
- `folderbase migrate`
- `folderbase transform analyze|plan|preview|approve|apply|reopen|recover|rollback`
- `folderbase version capture|history|restore`
- `folderbase workspace list|read|save`

Do not infer unpublished commands, private cloud endpoints, or repair
semantics. Use `folderbase --help` and subcommand help to confirm arguments.
