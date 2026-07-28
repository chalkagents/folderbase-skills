#!/bin/bash

set -euo pipefail

script_directory=$(
  CDPATH= cd -- "$(dirname -- "$0")" >/dev/null 2>&1
  pwd
)
repository_root=$(
  CDPATH= cd -- "$script_directory/.." >/dev/null 2>&1
  pwd
)
cd "$repository_root"

forbidden_pattern='brain|legacy|predecessor|/(Users|home)/[^/]+/'
content_hits=$(
  rg \
    --hidden \
    --text \
    --ignore-case \
    --line-number \
    --glob '!.git/**' \
    --glob '!scripts/check-public-eclipse.sh' \
    --glob '!node_modules/**' \
    "$forbidden_pattern" \
    . ||
    true
)
path_hits=$(
  git ls-files \
    --cached \
    --others \
    --exclude-standard |
    grep -Ei 'brain|legacy|predecessor' ||
    true
)

if [[ -n "$content_hits" || -n "$path_hits" ]]; then
  if [[ -n "$path_hits" ]]; then
    printf '%s\n' 'Public paths still use the former identity:' >&2
    printf '%s\n' "$path_hits" >&2
  fi
  if [[ -n "$content_hits" ]]; then
    printf '%s\n' 'Public content still uses the former identity:' >&2
    printf '%s\n' "$content_hits" >&2
  fi
  exit 1
fi

printf '%s\n' 'Public Folderbase-only surface contract is clean.'
