#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
version=$(jq -er '.version | select(type == "string" and length > 0)' "$repository_root/release-metadata.json")
api_baseline=$(jq -er '.apiBaseline | select(type == "string" and length > 0)' "$repository_root/release-metadata.json")
case "$version" in
    ''|*[!0-9.]*|.*|*.) echo "release-metadata.json version must be a stable numeric SemVer" >&2; exit 65 ;;
esac
printf '%s' "$version" | awk -F. 'NF == 3 && $1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/ { ok = 1 } END { exit(ok ? 0 : 1) }' || {
    echo "release-metadata.json version must contain major.minor.patch" >&2
    exit 65
}

expected_api_baseline="api/XCEasy-$version.swiftinterface"
[ "$api_baseline" = "$expected_api_baseline" ] || {
    echo "release-metadata.json apiBaseline must be $expected_api_baseline" >&2
    exit 65
}
baseline="$repository_root/$api_baseline"
[ -f "$baseline" ] || { echo "Release API baseline not found: $baseline" >&2; exit 66; }
grep -Fq "## [$version]" "$repository_root/CHANGELOG.md" || {
    echo "CHANGELOG.md has no section for $version" >&2
    exit 65
}
jq -e --arg version "$version" '
    .schemaVersion == "1.0.0" and
    .version == $version and
    (.minimumIOS | type == "string") and
    (.xcode | type == "string") and
    (.swift | type == "string") and
    (.telemetrySchema | type == "string") and
    .distribution == "Swift Package Manager" and
    .apiBaseline == "api/XCEasy-\($version).swiftinterface"
' "$repository_root/release-metadata.json" >/dev/null

"$repository_root/scripts/check-public-api-compatibility.sh" "$baseline"
echo "Release contract validated for XCEasy $version"
