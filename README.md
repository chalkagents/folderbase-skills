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
Skills release is `v0.2.1`, paired with Folderbase Core and CLI `0.2.1` at
commit `3a3e9df836a1fe0a2f33946205f899cc9483dc1b`. List its available skills
without installing:

```sh
DISABLE_TELEMETRY=1 npx --yes skills@1.5.20 add \
  https://github.com/chalkagents/folderbase-skills/tree/v0.2.1 \
  --list
```

Install the skill into the current project for the detected agent:

```sh
DISABLE_TELEMETRY=1 npx --yes skills@1.5.20 add \
  https://github.com/chalkagents/folderbase-skills/tree/v0.2.1 \
  --skill work-with-folderbase \
  --copy \
  --yes
```

Add `--global` for a user-level installation. The `v0.2.1` release is
install-tested for Codex, Claude Code, Cursor, Hermes Agent, and OpenClaw; the
same portable skill can work in other Agent Skills-compatible harnesses. The
tag in the source URL is intentional: review and install a version-pinned
Folderbase Skills release rather than whatever happens to be on the
repository's moving default branch.

During release review, the `v0.2.1` source URL becomes installable only after
this reviewed head is merged and tagged `v0.2.1`. Until both steps are
complete, test this checkout locally; do not substitute the moving default
branch or assume the tag already exists.

Install its matching Folderbase CLI before asking an agent to mutate a
Folderbase:

```sh
cargo install \
  --git https://github.com/chalkagents/folderbase.git \
  --rev 3a3e9df836a1fe0a2f33946205f899cc9483dc1b \
  --locked \
  folderbase-cli
```

Without a supported official CLI, the skill stays read-only.

## Contract

This Skills release is validated against Folderbase Core and CLI `0.2.1` at
the exact commit `3a3e9df836a1fe0a2f33946205f899cc9483dc1b`.

- One portable skill: `work-with-folderbase`
- Folderbase Core and CLI: `0.2.1`
- Folderbase Protocol: `0.1` with the declared `0.2` manifest additions
- Template Protocol: `0.2`

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
```

CI also validates the Agent Skills format, installs the skill into isolated
Codex, Claude Code, Cursor, Hermes Agent, and OpenClaw projects, and runs the
workflow against the exact Folderbase Core commit declared above.

## Security

Review any skill before installation: skills guide agents that can have broad
local authority. Report vulnerabilities privately as described in
[SECURITY.md](SECURITY.md).

Licensed under Apache-2.0.
