# Core v0.2.1 skill contract red

Observed before updating the live compatibility pin:

```text
FOLDERBASE_CORE_REF=3a3e9df836a1fe0a2f33946205f899cc9483dc1b \
  bash tests/core-contract.sh
CORE_V021_CONTRACT_RED_EXIT=1
```

The immutable Core v0.2.1 commit installed successfully as
`folderbase-cli v0.2.1`. The existing contract then failed at its exact CLI
version check because it still required `folderbase 0.2.0`. This proves the
patch-release upgrade is exercised through the public Git-installed CLI seam
rather than only through documentation assertions.
