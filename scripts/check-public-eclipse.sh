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
content_hits=''
path_hits=''
while IFS= read -r -d '' public_file
do
  if [[ -L "$public_file" ]]; then
    printf 'Public repository contains a symlink: %s\n' "$public_file" >&2
    exit 1
  fi
  if [[ "$public_file" != 'scripts/check-public-eclipse.sh' ]]; then
    if file_hits=$(grep -n -E -i "$forbidden_pattern" -- "$public_file"); then
      content_hits+="${content_hits:+$'\n'}$public_file:$file_hits"
    else
      grep_status=$?
      if [[ $grep_status -ne 1 ]]; then
        printf 'Unable to scan public file: %s\n' "$public_file" >&2
        exit 1
      fi
    fi
  fi
  if grep -E -i -q 'brain|legacy|predecessor' <<<"$public_file"; then
    path_hits+="${path_hits:+$'\n'}$public_file"
  fi
done < <(
  git ls-files \
    --cached \
    --others \
    --exclude-standard \
    -z
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
