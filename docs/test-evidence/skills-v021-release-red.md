# Skills v0.2.1 release contract RED evidence

This records the failing side of the release-state contract at the public
README seam. The fixed baseline is commit
`f7a2749548e96c1841fc8675f4a2242119b10aaa`, immediately before the release
pairing was published in the README.

Apply only the new acceptance assertions to a detached worktree at that exact
commit. The assertions require:

- the Skills `v0.2.1` source URL;
- Core and CLI `0.2.1` at
  `3a3e9df836a1fe0a2f33946205f899cc9483dc1b`;
- the current `Contract` heading; and
- an explicit warning that the source URL is unavailable until merge and tag.

Then run:

```bash
set +e
bash tests/acceptance.sh
red_exit=$?
set -e
printf 'SKILLS_V021_RELEASE_RED_EXIT=%s\n' "$red_exit"
```

Captured result:

```text
SKILLS_V021_RELEASE_RED_EXIT=1
```

The baseline README still named Skills `v0.2.0`, installed Core from
`f5ae84c5c247274a23cef901367fb83533a64f4d`, and labeled the current pairing a
development contract. The new assertions therefore failed before any release
publication or external mutation.
