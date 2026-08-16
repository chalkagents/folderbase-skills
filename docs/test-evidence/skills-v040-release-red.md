# Skills v0.4.0 release contract RED evidence

This records the failing side of the release-state contract at the public
README seam. The fixed baseline is the organization Change Set skill merge
`55557e0f105e4d2ea16c3aed7b96ed354fa47071`, immediately before the v0.4.0
release pairing was prepared.

The release assertions require:

- the Skills `v0.4.0` source URL;
- the exact Core v0.3.0 mutation commit
  `91530adbd984fdd61f22ecd73dd48c80e8364416`;
- the exact Core v0.7.2 Change Set commit
  `7439babec74242d9d162ab09f12f2f1b1b2c5cbe`;
- the current `Contract` heading; and
- an explicit warning that the source URL is unavailable until merge and tag.

Before changing `README.md`, the updated acceptance contract was run against
that fixed baseline:

```text
SKILLS_V040_RELEASE_RED_EXIT=1
```

The baseline still named `v0.3.0` as the published Skills release and labeled
the exact v0.7.2 Change Set profile as development coverage for a future
release. The new release assertions therefore failed before any tag or public
release was created.
