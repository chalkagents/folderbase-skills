# Core v0.2 skill contract red

Observed before updating the skill:

```text
FOLDERBASE_CORE_REF=f5ae84c5c247274a23cef901367fb83533a64f4d \
  bash tests/core-contract.sh
CORE_V02_CONTRACT_RED_EXIT=1
```

The immutable Core v0.2.0 CLI installed successfully and reported
`folderbase 0.2.0`. The existing contract then failed because the skill and
suite required `folderbase 0.1.0`. This proves the release upgrade is exercised
through the public CLI seam rather than only by documentation assertions.
