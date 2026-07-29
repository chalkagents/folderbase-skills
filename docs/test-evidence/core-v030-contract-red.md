# Core v0.3.0 skill contract RED evidence

Observed on 2026-07-29 before updating the live compatibility pin:

```text
FOLDERBASE_CORE_REF=91530adbd984fdd61f22ecd73dd48c80e8364416 \
  bash tests/core-contract.sh
CORE_V030_CONTRACT_RED_EXIT=1
```

The immutable public Core v0.3.0 commit installed successfully as
`folderbase-cli v0.3.0`. The existing contract then failed at its exact CLI
version check because it still required `folderbase 0.2.1`. This proves the
release upgrade is exercised through the public Git-installed CLI seam rather
than only through documentation assertions.
