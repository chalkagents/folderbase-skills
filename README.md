# Folderbase Skills

Official, portable agent skills for working safely with
[Folderbase](https://github.com/chalkagents/folderbase): a folder-based database
for humans and agents.

This repository is intentionally small. It teaches an agent how to discover,
inspect, initialize, navigate, edit, and propose reorganizations in a
Folderbase. The public Folderbase Core remains the only protocol and runtime
authority.

## Install

The pinned Skills CLI requires Node.js 22.20 or newer. List the available
skills without installing:

```sh
DISABLE_TELEMETRY=1 npx --yes skills@1.5.20 add \
  chalkagents/folderbase-skills \
  --list
```

Install the skill into the current project for the detected agent:

```sh
DISABLE_TELEMETRY=1 npx --yes skills@1.5.20 add \
  chalkagents/folderbase-skills \
  --skill work-with-folderbase \
  --copy \
  --yes
```

Add `--global` for a user-level installation. The same skill supports Codex,
Claude Code, and other Agent Skills-compatible harnesses.

Install the matching Folderbase CLI before asking an agent to mutate a
Folderbase:

```sh
cargo install \
  --git https://github.com/chalkagents/folderbase.git \
  --rev 2daf6968387e8c8111dfa03a922ed8866c015e15 \
  --locked \
  folderbase-cli
```

Without a supported official CLI, the skill stays read-only.

## Contract

- One portable skill: `work-with-folderbase`
- Folderbase Core and CLI: `0.1.0`
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
Codex and Claude Code projects, and runs the workflow against the immutable
Folderbase Core release.

## Security

Review any skill before installation: skills guide agents that can have broad
local authority. Report vulnerabilities privately as described in
[SECURITY.md](SECURITY.md).

Licensed under Apache-2.0.
