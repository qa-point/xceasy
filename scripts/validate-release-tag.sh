#!/bin/sh
set -eu

if [ "$#" -gt 1 ]; then
    echo "Usage: $0 [tag]" >&2
    exit 64
fi

repository_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
version=$(jq -er '.version | select(type == "string" and length > 0)' "$repository_root/release-metadata.json")
tag=${1:-${GITHUB_REF_NAME:-}}
[ -n "$tag" ] || { echo "Release tag is required" >&2; exit 64; }
tag=${tag#refs/tags/}
[ "$tag" = "v$version" ] || {
    echo "Release tag $tag does not match release metadata version $version" >&2
    exit 65
}

echo "Release tag matches release metadata: $tag"
