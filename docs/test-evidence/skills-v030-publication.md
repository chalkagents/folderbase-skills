# Skills v0.3.0 publication and install evidence

This records the public release proof for the version-pinned
`folderbase-skills` `v0.3.0` source.

## Red

Acceptance was changed to reject the temporary pre-tag warning and require the
public v0.3.0 distribution source before either default was updated:

```text
ACCEPTANCE_V030_PUBLICATION_RED_EXIT=1
```

The public v0.3.0 tag was then installed while the distribution gate still
expected the v0.2.1 lock and file identities. Its first published-install
identity assertion failed:

```text
DISTRIBUTION_V030_PUBLICATION_RED_EXIT=1
```

## Release identity

- Release:
  <https://github.com/chalkagents/folderbase-skills/releases/tag/v0.3.0>
- Annotated tag object:
  `b878e9599624b2b4d225b0c69d693f67f5268a9e`
- Tag target and release merge:
  `01a97dc6b8b86b9a0f2d3f2bc9f266395718d587`
- Release PR #10 hosted CI run
  [30459523188](https://github.com/chalkagents/folderbase-skills/actions/runs/30459523188)
  completed successfully at PR head
  `3b3b7278425d265c3432a62dd8ddb002fb0d47f4`.
- Post-merge `main` CI run
  [30459657581](https://github.com/chalkagents/folderbase-skills/actions/runs/30459657581)
  completed successfully at the exact tag target
  `01a97dc6b8b86b9a0f2d3f2bc9f266395718d587`.

## Green install proof

`tests/distribution.sh` installed the local checkout and the public `v0.3.0`
source into isolated project layouts for all five supported harnesses:

- Codex: `.agents/skills`
- Claude Code: `.claude/skills`
- Cursor: `.agents/skills`
- Hermes Agent: `.hermes/skills`
- OpenClaw: `skills`

For every published install, the gate asserted the version-pinned lock entry
and release file hashes:

- `skills-lock.json` `computedHash`:
  `0e3e8035100107c6dc1ff7aeb0fb968c058b7f9d7654f781323b0381b63b3e0f`
- `SKILL.md` SHA-256:
  `35718d726a76346fd1177636caaa6a61af9a6d20aa8cdf55a0273e05656a34ae`
- `references/protocol-surface.md` SHA-256:
  `7aa27908fe0da69a1da0a7795de046227a186b519cc3c0b269be416202396f6c`

The exact-tag distribution run completed successfully:

```text
DISTRIBUTION_V030_PUBLICATION_GREEN_EXIT=0
Local and version-pinned published Folderbase skill installs are valid.
```
