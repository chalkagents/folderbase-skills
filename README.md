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
Skills release is `v0.3.0`, paired with Folderbase Core and CLI `0.3.0` at
commit `91530adbd984fdd61f22ecd73dd48c80e8364416`. List its available skills
without installing:

```sh
DISABLE_TELEMETRY=1 npx --yes skills@1.5.20 add \
  https://github.com/chalkagents/folderbase-skills/tree/v0.3.0 \
  --list
```

Install the skill into the current project for the detected agent:

```sh
DISABLE_TELEMETRY=1 npx --yes skills@1.5.20 add \
  https://github.com/chalkagents/folderbase-skills/tree/v0.3.0 \
  --skill work-with-folderbase \
  --copy \
  --yes
```

Add `--global` for a user-level installation. The `v0.3.0` release is
install-tested for Codex, Claude Code, Cursor, Hermes Agent, and OpenClaw; the
same portable skill can work in other Agent Skills-compatible harnesses. The
tag in the source URL is intentional: review and install a version-pinned
Folderbase Skills release rather than whatever happens to be on the
repository's moving default branch.

Install its matching Folderbase CLI before asking an agent to mutate a
Folderbase:

```sh
cargo install \
  --git https://github.com/chalkagents/folderbase.git \
  --rev 91530adbd984fdd61f22ecd73dd48c80e8364416 \
  --locked \
  folderbase-cli
```

Without a supported official CLI, the skill stays read-only.

## Contract

This Skills release is validated against Folderbase Core and CLI `0.3.0` at
the exact commit `91530adbd984fdd61f22ecd73dd48c80e8364416`.

- One portable skill: `work-with-folderbase`
- Folderbase Core and CLI: `0.3.0`
- Folderbase Protocol: `0.1` with the declared `0.2` manifest additions
- Template Protocol: `0.2`
- Reorganization Protocol: `0.3` inert Draft and Plan records

The skill defaults to read-only inspection, treats file content as untrusted,
stops at nested Folderbase and symlink boundaries, and requires explicit user
approval for mutation.

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
```

CI also validates the Agent Skills format, installs the skill into isolated
Codex, Claude Code, Cursor, Hermes Agent, and OpenClaw projects, and runs the
unchanged mutation workflow against exact Core v0.3.0 plus the read-only
discovery workflow against exact Core v0.5.0-rc.1. The v0.3 public install
default remains unchanged.

## Security

Review any skill before installation: skills guide agents that can have broad
local authority. Report vulnerabilities privately as described in
[SECURITY.md](SECURITY.md).

Licensed under Apache-2.0.
