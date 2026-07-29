# Skills v0.3.0 release contract RED evidence

This records the failing side of the release-state contract at the public
README seam. The fixed baseline is compatibility merge
`91809afe91fec56cd1bfaac5d9328055bb2c79fc`, immediately before the v0.3.0
release pairing was prepared.

The standalone assertions require:

- the Skills `v0.3.0` source URL;
- Core and CLI `0.3.0` at
  `91530adbd984fdd61f22ecd73dd48c80e8364416`;
- the current `Contract` heading; and
- an explicit warning that the source URL is unavailable until merge and tag.

From this repository, run:

```bash
set +e
release_contract() {
  baseline_readme=$(
    git show 91809afe91fec56cd1bfaac5d9328055bb2c79fc:README.md
  )
  normalized_readme_text=$(
    printf '%s\n' "$baseline_readme" |
      tr '\n' ' ' |
      tr -s '[:space:]' ' '
  )

  grep -F -q -- 'current Folderbase Skills release is `v0.3.0`' \
    <<<"$normalized_readme_text" &&
    grep -F -q -- \
      'https://github.com/chalkagents/folderbase-skills/tree/v0.3.0' \
      <<<"$baseline_readme" &&
    grep -F -q -- \
      '91530adbd984fdd61f22ecd73dd48c80e8364416' \
      <<<"$baseline_readme" &&
    grep -F -q -- \
      'becomes installable only after this reviewed head is merged and tagged' \
      <<<"$normalized_readme_text" &&
    grep -F -x -q -- '## Contract' <<<"$baseline_readme"
}

release_contract
red_exit=$?
set -e
printf 'SKILLS_V030_RELEASE_RED_EXIT=%s\n' "$red_exit"
```

Captured result:

```text
SKILLS_V030_RELEASE_RED_EXIT=1
```

The baseline still named the public Skills release and tag `v0.2.1`, installed
Core v0.2.1, and labeled the v0.3.0 pairing as a development contract. The
standalone assertions therefore failed at the claimed README seam before any
release publication or external mutation.
