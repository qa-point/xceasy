#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <output.swiftinterface>" >&2
    exit 64
fi

output=$1
repository_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
developer_dir=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
derived_data=$(mktemp -d "${TMPDIR:-/tmp}/xceasy-api-derived.XXXXXX")
trap 'rm -rf "$derived_data"' EXIT

if [ ! -d "$repository_root/XCEasy.xcworkspace" ]; then
    if [ -n "${TUIST_BIN:-}" ] && [ -x "$TUIST_BIN" ]; then
        tuist_bin=$TUIST_BIN
    elif command -v tuist >/dev/null 2>&1; then
        tuist_bin=$(command -v tuist)
    elif [ -x "$HOME/.local/share/mise/installs/tuist/4.203.3/tuist" ]; then
        tuist_bin="$HOME/.local/share/mise/installs/tuist/4.203.3/tuist"
    else
        echo "Tuist 4.203.3 is unavailable; run 'mise install'" >&2
        exit 69
    fi
    (cd "$repository_root" && DEVELOPER_DIR="$developer_dir" "$tuist_bin" generate --no-open)
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
