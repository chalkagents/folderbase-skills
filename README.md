# Folderbase Skills

Official, portable agent skills for working safely with
[Folderbase](https://github.com/chalkagents/folderbase): a folder-based database
for humans and agents.

This repository is intentionally small. It teaches an agent how to discover,
inspect, initialize, navigate, edit, and propose reorganizations in a
Folderbase. The public Folderbase Core remains the only protocol and runtime
authority.

## Install

The pinned Skills CLI requires Node.js 22.20 or newer. The current Folderbase
Skills release is `v0.4.0`. It supports the exact Core `v0.3.0` mutation
profile at commit `91530adbd984fdd61f22ecd73dd48c80e8364416` and the exact Core
`v0.7.2` Change Set profile at commit
`7439babec74242d9d162ab09f12f2f1b1b2c5cbe`. List its available skill without
installing:

```sh
DISABLE_TELEMETRY=1 npx --yes skills@1.5.20 add \
  https://github.com/chalkagents/folderbase-skills/tree/v0.4.0 \
  --list
```

Install the skill into the current project for the detected agent:

```sh
DISABLE_TELEMETRY=1 npx --yes skills@1.5.20 add \
  https://github.com/chalkagents/folderbase-skills/tree/v0.4.0 \
  --skill work-with-folderbase \
  --copy \
  --yes
```

Add `--global` for a user-level installation. The `v0.4.0` release is
install-tested for Codex, Claude Code, Cursor, Hermes Agent, OpenClaw, and
OpenCode; the same portable skill can work in other Agent Skills-compatible
harnesses. The tag in the source URL is intentional: review and install a
version-pinned Folderbase Skills release rather than whatever happens to be on
the repository's moving default branch.

Folderbase Skills is also discoverable in the
[public skills.sh catalog](https://www.skills.sh/chalkagents/folderbase-skills/work-with-folderbase)
and through the canonical repository shorthand:

```sh
DISABLE_TELEMETRY=1 npx --yes skills@1.5.20 add \
  chalkagents/folderbase-skills \
  --list
```

The catalog and shorthand intentionally resolve the moving default branch for
discovery. They are not an immutable release identity. Use the version-pinned
immutable tag above when installing a reproducible Folderbase mutation
workflow.

Install the exact Folderbase CLI required by the intended workflow. Use Core
`v0.3.0` for initialization, migration, version, and workspace-save work:

```sh
cargo install \
  --git https://github.com/chalkagents/folderbase.git \
  --rev 91530adbd984fdd61f22ecd73dd48c80e8364416 \
  --locked \
  folderbase-cli
```

Use Core `v0.7.2` for work inside an already-authorized ordinary checkout that
must return a reviewable Change Set:

```sh
cargo install \
  --git https://github.com/chalkagents/folderbase.git \
  --rev 7439babec74242d9d162ab09f12f2f1b1b2c5cbe \
  --locked \
  folderbase-cli
```

Do not substitute an untested version. Without a supported official CLI, the
skill stays read-only.

## Contract

This Skills release validates separate, narrow Core profiles instead of
pretending every Core version has the same command surface.

- One portable skill: `work-with-folderbase`
- Exact mutation profile: Core and CLI `0.3.0` at
  `91530adbd984fdd61f22ecd73dd48c80e8364416`
- Exact read-only discovery candidate: Core and CLI `0.5.0-rc.1` at
  `45de7804bb4e57224e5b9495e4394441ce652f0b`
- Exact scoped Change Set handoff: Core and CLI `0.7.2` at
  `7439babec74242d9d162ab09f12f2f1b1b2c5cbe`, with stable
  `folderbase.change-set@0.1.0`
- Folderbase Protocol: `0.1` with the declared `0.2` manifest additions
- Template Protocol: `0.2`
- Reorganization Protocol: `0.3` inert Draft and Plan records

The skill defaults to read-only inspection, treats file content as untrusted,
stops at nested Folderbase and symlink boundaries, and requires explicit user
approval for mutation.

In the Change Set profile, an agent receives an already-authorized ordinary
checkout, works with every file type using normal filesystem tools, and
returns one immutable Change Set plus provider-neutral staging for a separate
Folderbase App review. The skill does not create sharing authority and the
working agent does not apply its own proposal. Read-only assessment is not
approval.

## Verify

```sh
bash tests/acceptance.sh
bash scripts/check-ci-policy.sh
npm ci --ignore-scripts
bash tests/distribution.sh
bash tests/core-contract.sh
FOLDERBASE_CORE_CONTRACT=v0.5-read-only \
FOLDERBASE_CORE_REF=45de7804bb4e57224e5b9495e4394441ce652f0b \
  bash tests/core-contract.sh
FOLDERBASE_CORE_CONTRACT=v0.7.2-change-set \
FOLDERBASE_CORE_REF=7439babec74242d9d162ab09f12f2f1b1b2c5cbe \
  bash tests/core-contract.sh
```

CI also validates the Agent Skills format, installs the skill into isolated
Codex, Claude Code, Cursor, Hermes Agent, OpenClaw, and OpenCode projects, and
runs the unchanged mutation workflow against exact Core v0.3.0 plus the
read-only discovery workflow against exact Core v0.5.0-rc.1 and the scoped
Change Set handoff against exact Core v0.7.2. The public installation gate uses
the exact `v0.4.0` tag, lock identity, and release file hashes.

## Security

Review any skill before installation: skills guide agents that can have broad
local authority. Report vulnerabilities privately as described in
[SECURITY.md](SECURITY.md).

Licensed under Apache-2.0.
