# Tested Folderbase protocol surface

This skill treats the public
[`chalkagents/folderbase`](https://github.com/chalkagents/folderbase) repository
as the only protocol authority. It does not copy schemas, templates, adapter
text, or implementation logic.

## Compatibility pin

- Verified release tag: `v0.2.1`
- Verified core commit:
  `3a3e9df836a1fe0a2f33946205f899cc9483dc1b`
- Crate and CLI version: `0.2.1`
- Folderbase Protocol 0.1
- Folderbase manifest schema additions in Protocol 0.2
- Template Protocol 0.2

The `0.x` surface is pre-stable. Mutation requires this exact tested CLI
release and protocol range. Any untested CLI release remains read-only until
this reference and the acceptance suite are updated.

## Authoritative documents

- [Protocol specification](https://github.com/chalkagents/folderbase/blob/3a3e9df836a1fe0a2f33946205f899cc9483dc1b/docs/protocol-spec.md)
- [Template protocol](https://github.com/chalkagents/folderbase/blob/3a3e9df836a1fe0a2f33946205f899cc9483dc1b/docs/template-protocol.md)
- [Schemas and conformance artifacts](https://github.com/chalkagents/folderbase/blob/3a3e9df836a1fe0a2f33946205f899cc9483dc1b/protocol/README.md)

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
its rendered entry lacks sections that CLI 0.2.1 validation requires. Preview
it only when diagnosing existing provenance; do not apply it. New project
initialization must use `folderbase.project@0.2.2`. Both packages take the same
three required text answers.

`folderbase_name` is an optional text answer on every current package except
project 0.2.1. Prefer the explicit `--name` surface and do not ask for that
optional answer when the name is already known. The CLI validates question IDs,
answer types, required answers, duplicate answers, and exact built-in template
versions. There is no external template loader, template-list command,
post-initialization template expansion command, or in-place reorganization
command in CLI 0.2.1.

Packages use additive `create_if_missing` artifacts. They preserve every
existing target and record template provenance as an origin, not as ongoing
layout conformance or authority.

Without `--no-agent-adapters`, initialization creates the managed Codex and
Claude adapters when their targets are absent and records both in the manifest.
With the flag, the manifest adapter list is empty, existing `AGENTS.md` and
`CLAUDE.md` files remain preserved, and neither adapter target is created or
edited.
