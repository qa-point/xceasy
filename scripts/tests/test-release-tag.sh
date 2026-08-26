#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
version=$(jq -er '.version | select(type == "string" and length > 0)' "$repository_root/release-metadata.json")
"$repository_root/scripts/validate-release-tag.sh" "v$version" >/dev/null
"$repository_root/scripts/validate-release-tag.sh" "refs/tags/v$version" >/dev/null
if "$repository_root/scripts/validate-release-tag.sh" "v999.0.0" >/dev/null 2>&1; then
    echo "Release tag validator accepted a mismatched tag" >&2
    exit 1
fi
echo "Release tag contract test passed"
