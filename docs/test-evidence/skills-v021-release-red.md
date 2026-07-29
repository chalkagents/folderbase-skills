# Skills v0.2.1 release contract RED evidence

This records the failing side of the release-state contract at the public
README seam. The fixed baseline is commit
`f7a2749548e96c1841fc8675f4a2242119b10aaa`, immediately before the release
pairing was published in the README.

Run the release-state assertions directly against `README.md` from that exact
commit. This excludes the new evidence-file registration checks, so the failure
can only come from the public README seam under test. The assertions require:

- the Skills `v0.2.1` source URL;
- Core and CLI `0.2.1` at
  `3a3e9df836a1fe0a2f33946205f899cc9483dc1b`;
- the current `Contract` heading; and
- an explicit warning that the source URL is unavailable until merge and tag.

From this repository, run:

```bash
set +e
release_contract() {
  baseline_readme=$(
    git show f7a2749548e96c1841fc8675f4a2242119b10aaa:README.md
  )
  normalized_readme_text=$(
    printf '%s\n' "$baseline_readme" |
      tr '\n' ' ' |
      tr -s '[:space:]' ' '
  )

  grep -F -q -- 'current Folderbase Skills release is `v0.2.1`' \
    <<<"$normalized_readme_text" &&
    grep -F -q -- \
      'https://github.com/chalkagents/folderbase-skills/tree/v0.2.1' \
      <<<"$baseline_readme" &&
    grep -F -q -- \
      '3a3e9df836a1fe0a2f33946205f899cc9483dc1b' \
      <<<"$baseline_readme" &&
    grep -F -q -- \
      'becomes installable only after this reviewed head is merged and tagged' \
      <<<"$normalized_readme_text" &&
    grep -F -x -q -- '## Contract' <<<"$baseline_readme"
}

release_contract
red_exit=$?
set -e
printf 'SKILLS_V021_RELEASE_RED_EXIT=%s\n' "$red_exit"
```

Captured result:

```text
SKILLS_V021_RELEASE_RED_EXIT=1
```

The first README assertion failed because the baseline still named Skills
`v0.2.0`. It also installed Core from
`f5ae84c5c247274a23cef901367fb83533a64f4d`, and labeled the current pairing a
development contract. The standalone assertions therefore failed at the
claimed README seam before any release publication or external mutation.
