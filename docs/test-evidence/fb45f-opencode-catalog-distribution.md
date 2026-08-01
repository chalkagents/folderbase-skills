# FB-45F OpenCode and catalog distribution evidence

This records the test-first distribution proof added on 2026-08-02 from
`folderbase-skills` `main` commit
`5d45e089a0e1931bf1fdcfafda1a9d6ab9d4f934`.

## Red

The public acceptance gate was changed first to require OpenCode at the
existing install seam, canonical repository-shorthand discovery, and an
explicit discovery-versus-release trust boundary. Before implementation it
failed as expected:

```text
FB45F_ACCEPTANCE_RED_EXIT=1
```

The missing behavior was OpenCode local and published installation, the
public skills.sh location, the pinned Skills CLI shorthand command, and the
catalog-source gate. No production behavior was changed to manufacture the
failure.

## Green distribution proof

The gate uses `skills@1.5.20` and proves that the Skills CLI discovers
`work-with-folderbase` through the bounded canonical shorthand
`chalkagents/folderbase-skills`. It then installs the local checkout and the
exact public `v0.3.0` source into an isolated OpenCode project at
`.agents/skills/work-with-folderbase`.

The exact-tag OpenCode install asserts the same release identity used by the
other supported harnesses:

- Annotated tag object:
  `b878e9599624b2b4d225b0c69d693f67f5268a9e`
- Tag target:
  `01a97dc6b8b86b9a0f2d3f2bc9f266395718d587`
- Folderbase Core v0.3 exact pin:
  `91530adbd984fdd61f22ecd73dd48c80e8364416`
- `skills-lock.json` `computedHash`:
  `0e3e8035100107c6dc1ff7aeb0fb968c058b7f9d7654f781323b0381b63b3e0f`
- Installed `SKILL.md` SHA-256:
  `35718d726a76346fd1177636caaa6a61af9a6d20aa8cdf55a0273e05656a34ae`
- Installed `references/protocol-surface.md` SHA-256:
  `7aa27908fe0da69a1da0a7795de046227a186b519cc3c0b269be416202396f6c`

The focused gates completed successfully:

```text
FB45F_ACCEPTANCE_GREEN_EXIT=0
Folderbase skill acceptance contract is clean.

FB45F_DISTRIBUTION_GREEN_EXIT=0
Local and version-pinned published Folderbase skill installs are valid.
```

## Trust boundary and non-claims

The catalog page and canonical shorthand intentionally discover the moving
default branch. They are convenient discovery surfaces, not immutable release
identities. Reproducible mutation workflows must continue to install the
version-pinned immutable tag documented in the README.

This proof does not publish a new release, invoke an OpenCode runtime, alter a
Core pin or skill mutation policy, define Cloud or sync contracts, or clear
third-party catalog assessments. At verification time the Skills CLI still
reported its external Agent Trust Hub pass alongside Socket and Snyk warnings;
those assessments remain externally owned signals rather than release proof.
