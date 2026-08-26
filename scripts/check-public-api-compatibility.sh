#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
api_baseline=$(jq -er '.apiBaseline | select(type == "string" and length > 0)' "$repository_root/release-metadata.json")
baseline=${1:-"$repository_root/$api_baseline"}
candidate=$(mktemp "${TMPDIR:-/tmp}/xceasy-public-api.XXXXXX.swiftinterface")
trap 'rm -f "$candidate"' EXIT

"$repository_root/scripts/generate-public-api-interface.sh" "$candidate" >/dev/null
"$repository_root/scripts/compare-public-api.sh" "$baseline" "$candidate"
