#!/bin/sh
set -eu

script_directory=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
validator="$script_directory/../validate-swift-documentation.sh"
fixture_root=$(mktemp -d "${TMPDIR:-/tmp}/xceasy-swift-docs.XXXXXX")
trap 'rm -rf "$fixture_root"' EXIT HUP INT TERM

cat >"$fixture_root/Documented.swift" <<'SWIFT'
struct Documented {
    /// Returns a deterministic fixture value.
    ///
    /// - Parameter input: Fixture input.
    /// - Returns: The unchanged input.
    func value(input: Int) -> Int { input }
}
SWIFT
"$validator" "$fixture_root" >/dev/null

cat >"$fixture_root/Undocumented.swift" <<'SWIFT'
struct Undocumented {
    func value() {}
}
SWIFT
if "$validator" "$fixture_root" >/dev/null 2>&1; then
    echo "Documentation validator accepted an undocumented function" >&2
    exit 1
fi
rm -f "$fixture_root/Undocumented.swift"

cat >"$fixture_root/Legacy.swift" <<'SWIFT'
//
//  Legacy.swift
//  Created by Someone on 01.01.2020.
//

struct Legacy {}
SWIFT
if "$validator" "$fixture_root" >/dev/null 2>&1; then
    echo "Documentation validator accepted a legacy file banner" >&2
    exit 1
fi

echo "Swift documentation contract tests passed"
