# Skills v0.2.1 publication and install evidence

This records the public release proof for the version-pinned
`folderbase-skills` `v0.2.1` source.

## Red

The publication contract was changed before its defaults. Acceptance rejected
the old `v0.2.0` distribution source:

```text
ACCEPTANCE_PUBLICATION_RED_EXIT=1
```

The distribution gate was then run with its old `v0.2.0` source and the
expected `v0.2.1` release identity. The Skills CLI reported
`Source: https://github.com/chalkagents/folderbase-skills.git @ v0.2.0`, and
the lock-file identity assertion failed:

```text
DISTRIBUTION_PUBLICATION_RED_EXIT=1
```

## Release identity

- Release:
  <https://github.com/chalkagents/folderbase-skills/releases/tag/v0.2.1>
- Annotated tag object:
  `1bc5a960226d0d5a396f06f0a068bdef2129069c`
- Tag target and merged `main` head:
  `172382a5548b7761527173a810d72e3739564f70`
- Release PR #7 hosted CI run
  [30410246722](https://github.com/chalkagents/folderbase-skills/actions/runs/30410246722)
  completed successfully at PR head
  `18067570d960b84778c4898ffc2180585875d875`.
- Post-merge `main` CI run
  [30410323435](https://github.com/chalkagents/folderbase-skills/actions/runs/30410323435)
  completed successfully at the exact merged head
  `172382a5548b7761527173a810d72e3739564f70`.

## Green install proof

`tests/distribution.sh` installed the local checkout and the public `v0.2.1`
source into isolated project layouts for all five supported harnesses:

- Codex: `.agents/skills`
- Claude Code: `.claude/skills`
- Cursor: `.agents/skills`
- Hermes Agent: `.hermes/skills`
- OpenClaw: `skills`

For every published install, the gate asserted the version-pinned lock entry
and release file hashes:

- `skills-lock.json` `computedHash`:
  `d829f6f4a218b8771e11f42de905ab2b24e15707a05e16dfb180414ba8749fde`
- `SKILL.md` SHA-256:
  `6127734f977c9b2bf983043e1f30666ab920efc7f732943bab630fa923d29a97`
- `references/protocol-surface.md` SHA-256:
  `a41b2bc5d83dad6df2a2a3ceca0618980b9f54db4063a82d0133c5239c7b2821`

The exact-tag distribution run completed successfully:

```text
DISTRIBUTION_PUBLICATION_GREEN_EXIT=0
Local and version-pinned published Folderbase skill installs are valid.
```
