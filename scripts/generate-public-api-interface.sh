#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <output.swiftinterface>" >&2
    exit 64
fi

output=$1
repository_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$repository_root/scripts/lib/environment.sh"
resolve_xcode_developer_dir
developer_dir=$DEVELOPER_DIR
derived_data=$(mktemp -d "${TMPDIR:-/tmp}/xceasy-api-derived.XXXXXX")
trap 'rm -rf "$derived_data"' EXIT

if [ ! -d "$repository_root/XCEasy.xcworkspace" ]; then
    (cd "$repository_root" && run_tuist generate --no-open)
fi

(cd "$repository_root" && DEVELOPER_DIR="$developer_dir" xcodebuild -quiet build \
    -workspace XCEasy.xcworkspace \
    -scheme XCEasy \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$derived_data" \
    CODE_SIGNING_ALLOWED=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES)

interface=$(find "$derived_data/Build/Products" -path '*/XCEasy.framework/Modules/XCEasy.swiftmodule/arm64-apple-ios-simulator.swiftinterface' -print -quit)
[ -n "$interface" ] && [ -f "$interface" ] || {
    echo "XCEasy public Swift interface was not produced" >&2
    exit 66
}
mkdir -p "$(dirname "$output")"
cp "$interface" "$output"
echo "Public API interface written to $output"
