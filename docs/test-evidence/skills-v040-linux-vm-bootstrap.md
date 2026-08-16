# Skills v0.4.0 fresh-Linux bootstrap evidence

Date: 2026-08-17

Tracking: [folderbase-skills#19](https://github.com/chalkagents/folderbase-skills/issues/19)

## Outcome

Prove the shortest immutable public bootstrap that a third-party or future
managed remote-agent VM can reuse after it already receives an authorized
ordinary checkout. The test combines the public Skills v0.4.0 tag and public
Core CLI v0.7.2 npm package inside isolated user/npm state, then returns an
immutable Change Set for separate review.

## RED

`tests/acceptance.sh` first required the Linux bootstrap script, CI step,
evidence record, and bounded README claims. It exited nonzero before those
artifacts existed. No skill or runtime behavior changed before that failure.

## GREEN contract

The acceptance must prove:

- Linux is the expected host in the hosted job;
- Node.js is at least 22.20;
- `skills@1.5.20` installs the exact Skills v0.4.0 tag into an isolated Codex
  project and reproduces its lock identity plus published file hashes;
- `@folderbase/cli@0.7.2` matches its immutable registry integrity and reports
  `folderbase 0.7.2`;
- exact Core exposes stable `folderbase.change-set@0.1.0`;
- an exact locally constructed authorization fixture excludes a private
  sibling and creates an ordinary checkout;
- Markdown, binary, sparse media-shaped, SQLite database, PDF-shaped, unknown,
  and Git repository files remain normal preserved bytes;
- normal file and database edits produce `folderbase-change-set-v1` plus
  provider-neutral staging;
- neither handoff artifact contains the private sibling marker; and
- separate assessment is clean and does not mutate the source folder.

During the fresh-clone verification, `npm audit` identified the existing
`skills-ref` lock on `js-yaml` 4.3.0 as affected by CVE-2026-59870. The direct
dependency already allowed the patched release, so this slice refreshes only
that transitive lock entry to 4.3.1 and adds a high-severity audit gate to CI.
No published skill or runtime dependency changes.

## Verification

```text
bash tests/acceptance.sh
bash -n tests/linux-vm-bootstrap.sh
FOLDERBASE_EXPECT_OS=Linux tests/linux-vm-bootstrap.sh
bash scripts/check-ci-policy.sh
npm audit --audit-level=high
```

Local contract parity passed on macOS with the bundled Node.js 24 runtime; it
installed the public artifacts, preserved the mixed-file checkout, produced a
clean Change Set, and retained the private sibling boundary. Hosted Ubuntu run
[31965731005](https://github.com/chalkagents/folderbase-skills/actions/runs/31965731005)
then passed the new fresh-Linux bootstrap plus every existing exact Core and
distribution gate in 3m59s at commit `0530add`.

## Explicit nonclaims

This is not Live Folder link redemption, Cloud authentication or
authorization, synchronization, materialization, a VM runner, hosted-agent
lifecycle, secrets/network policy, or an Apply authority. The test begins only
after exact Core locally constructs an authorized checkout fixture, and the
working agent returns its proposal to a separate reviewer.
