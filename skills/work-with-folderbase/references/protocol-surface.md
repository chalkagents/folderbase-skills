# Tested Folderbase protocol surface

This skill treats the public
[`chalkagents/folderbase`](https://github.com/chalkagents/folderbase) repository
as the only protocol authority. It does not copy schemas, templates, adapter
text, or implementation logic.

## Compatibility pin

- Verified release tag: `v0.3.0`
- Verified core commit:
  `91530adbd984fdd61f22ecd73dd48c80e8364416`
- Crate and CLI version: `0.3.0`
- Folderbase Protocol 0.1
- Folderbase manifest schema additions in Protocol 0.2
- Template Protocol 0.2
- Reorganization Protocol 0.3

The `0.x` surface is pre-stable. Mutation requires this exact tested CLI
release and protocol range. Any untested CLI release remains read-only until
this reference and the acceptance suite are updated.

## Authoritative documents

- [Protocol specification](https://github.com/chalkagents/folderbase/blob/91530adbd984fdd61f22ecd73dd48c80e8364416/docs/protocol-spec.md)
- [Template protocol](https://github.com/chalkagents/folderbase/blob/91530adbd984fdd61f22ecd73dd48c80e8364416/docs/template-protocol.md)
- [Reorganization protocol](https://github.com/chalkagents/folderbase/blob/91530adbd984fdd61f22ecd73dd48c80e8364416/docs/reorganization-protocol.md)
- [Schemas and conformance artifacts](https://github.com/chalkagents/folderbase/blob/91530adbd984fdd61f22ecd73dd48c80e8364416/protocol/README.md)

## Stable CLI operations

- `folderbase attest`
- `folderbase inspect`
- `folderbase init`
- `folderbase validate`
- `folderbase migrate`
- `folderbase transform analyze|plan|preview|approve|apply|reopen|recover|rollback`
- `folderbase version capture|history|restore`
- `folderbase workspace list|read|save`

Do not infer unpublished commands, private cloud endpoints, or repair
semantics. Use `folderbase --help` and subcommand help to confirm arguments.

`folderbase attest PATH --json` returns the display root, Folderbase ID,
protocol version, exact manifest SHA-256, and one device-local root-instance
SHA-256. The receipt is point-in-time evidence about one local materialization,
not proof of ongoing continuity. Before later Folderbase work after a session
boundary or possible replacement, attest again and compare the logical tuple
and root-instance digest. It is not authorization, a share grant, portable
cloud identity, a Folderbase Version, evidence that ordinary content is
unchanged, or evidence that content is synchronized or Agent-ready. Do not
compare the root-instance digest across devices.

Core v0.3.0 has no sharing or synchronization command. Those operations require
a separately authenticated product grant and materialization workflow when
they are managed Live Folder sharing or sync. Ordinary filesystem copies,
clones, and mounts remain possible under explicit user intent and real OS or
harness authority, but Core attestation does not create that authority or prove
that independently supplied folders are synchronized. Do not infer or invent a
managed product surface from this Core reference.

## Tested initialization surface

Discover the installed surface with `folderbase --help` and
`folderbase init --help`. For the exact Core and CLI pin above, `init` accepts
`--dry-run`, `--name`, `--kind`, `--no-agent-adapters`, `--template`,
repeatable `--answer QUESTION_ID=ANSWER`, and `--json`.
It also returns an opaque `plan_digest` from `--dry-run`, accepts
`--expected-plan-digest DIGEST` for apply, and returns
`applied_plan_digest` on success.

The immutable release contains these built-in packages:

| Exact selector | Kind | Intended starting boundary | Required text answers |
| --- | --- | --- | --- |
| `folderbase.person@0.2.0` | `person` | One person's durable context | `purpose`, `current_state`, `next_action` |
| `folderbase.organization@0.2.0` | `organization` | Company or team operations | `purpose`, `current_state`, `next_action` |
| `folderbase.customer@0.2.0` | `customer` | Separately governed customer context | `boundary_reason`, `purpose`, `current_state`, `next_action` |
| `folderbase.engagement@0.2.0` | `engagement` | Relationship, obligations, and shared outcome | `purpose`, `current_state`, `next_action` |
| `folderbase.project@0.2.2` | `project` | One bounded outcome | `purpose`, `current_state`, `next_action` |
| `folderbase.temporary@0.2.0` | `temporary` | Short-lived work with an exit condition | `purpose`, `current_state`, `next_action` |
| `folderbase.custom@0.2.0` | `custom` | A boundary no other starter fits honestly | `purpose`, `current_state`, `next_action` |

`folderbase.project@0.2.1` is also discoverable in the immutable release, but
its rendered entry lacks sections that CLI 0.3.0 validation requires. Preview
it only when diagnosing existing provenance; do not apply it. New project
initialization must use `folderbase.project@0.2.2`. Both packages take the same
three required text answers.

`folderbase_name` is an optional text answer on every current package except
project 0.2.1. Prefer the explicit `--name` surface and do not ask for that
optional answer when the name is already known. The CLI validates question IDs,
answer types, required answers, duplicate answers, and exact built-in template
versions. There is no external template loader, template-list command,
post-initialization template expansion command, or in-place reorganization
command in CLI 0.3.0. Core v0.3.0 publishes inert Reorganization Protocol 0.3
Draft and Plan schemas, but the CLI does not apply or recover those records.
Possession of a record grants no authority.

The released `transform` command is a folder-to-Folderbase adoption and
supported boundary-migration workflow. It is not an apply surface for
Reorganization Protocol 0.3 and must not restructure an already initialized
Folderbase in place.

Packages use additive `create_if_missing` artifacts. They preserve every
existing target and record template provenance as an origin, not as ongoing
layout conformance or authority.

Without `--no-agent-adapters`, initialization creates the managed Codex and
Claude adapters when their targets are absent and records both in the manifest.
With the flag, the manifest adapter list is empty, existing `AGENTS.md` and
`CLAUDE.md` files remain preserved, and neither adapter target is created or
edited.
