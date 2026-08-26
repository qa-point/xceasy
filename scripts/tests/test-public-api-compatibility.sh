#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"' EXIT

cat > "$temporary_directory/baseline.swiftinterface" <<'SWIFT'
// swift-interface-format-version: 1.0
import Swift
public struct Banner {
  public init()
  public func close()
}
SWIFT
cat > "$temporary_directory/addition.swiftinterface" <<'SWIFT'
// swift-interface-format-version: 1.0
import Swift
public struct Banner {
  public init()
  public func close()
  public func title() -> Swift.String
}
SWIFT
cat > "$temporary_directory/breaking.swiftinterface" <<'SWIFT'
// swift-interface-format-version: 1.0
import Swift
public struct Banner {
  public init()
  public func dismiss()
}
SWIFT

"$repository_root/scripts/compare-public-api.sh" \
    "$temporary_directory/baseline.swiftinterface" \
    "$temporary_directory/addition.swiftinterface" >/dev/null
if "$repository_root/scripts/compare-public-api.sh" \
    "$temporary_directory/baseline.swiftinterface" \
    "$temporary_directory/breaking.swiftinterface" >/dev/null 2>&1; then
    echo "Compatibility checker accepted a removed public method" >&2
    exit 1
fi

echo "Public API compatibility contract test passed"
