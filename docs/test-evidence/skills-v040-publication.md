# Skills v0.4.0 publication and install evidence

This records the public release proof for the version-pinned
`folderbase-skills` `v0.4.0` source.

## Red

After tag publication, acceptance was changed to reject the temporary pre-tag
warning and require the public v0.4.0 distribution source before either value
was updated:

```text
ACCEPTANCE_V040_PUBLICATION_RED_EXIT=1
```

The public v0.4.0 tag was then installed while the distribution gate still
expected the v0.3.0 lock and file identities. Its first exact-tag identity
assertion failed:

```text
DISTRIBUTION_V040_PUBLICATION_RED_EXIT=1
```

## Release identity

- Release:
  <https://github.com/chalkagents/folderbase-skills/releases/tag/v0.4.0>
- Annotated tag object:
  `6135fc0c7bb2e1fc3b4338e61bdcd9edaf6b5aad`
- Tag target and release merge:
  `27e1b361e591de6fe76c4efb3f8c49e0aab02a17`
- Release PR #17 hosted CI run
  [31938308870](https://github.com/chalkagents/folderbase-skills/actions/runs/31938308870)
  completed successfully at PR head
  `4c700b2288a190f4f88a42e1ec48cfe4699aa072`.
- Post-merge `main` CI run
  [31938507491](https://github.com/chalkagents/folderbase-skills/actions/runs/31938507491)
  completed successfully at the exact tag target
  `27e1b361e591de6fe76c4efb3f8c49e0aab02a17`.

## Green install proof

`tests/distribution.sh` installs the local checkout and public `v0.4.0` source
into isolated project layouts for all six supported harnesses:

- Codex: `.agents/skills`
- Claude Code: `.claude/skills`
- Cursor: `.agents/skills`
- Hermes Agent: `.hermes/skills`
- OpenClaw: `skills`
- OpenCode: `.agents/skills`

For every published install, the gate asserts the version-pinned lock entry and
release file hashes:

- `skills-lock.json` `computedHash`:
  `6bff7b1dd04b7aae5b361a2be773a6cfa4d9fde8c98578638abce76821a93f5a`
- `SKILL.md` SHA-256:
  `82b871a5d9125b58c91481e7c9c115ea539939ece67f978ca7ed35f64b2af4a3`
- `references/protocol-surface.md` SHA-256:
  `543cfb24febe388a3833999dcd781c83caf12ef14ca59c1cb4cc93964bf78792`

The exact-tag distribution run completed successfully:

```text
DISTRIBUTION_V040_PUBLICATION_GREEN_EXIT=0
Local and version-pinned published Folderbase skill installs are valid.
```
