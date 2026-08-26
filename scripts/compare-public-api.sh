#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <baseline.swiftinterface> <candidate.swiftinterface>" >&2
    exit 64
fi

baseline=$1
candidate=$2
[ -f "$baseline" ] || { echo "Public API baseline not found: $baseline" >&2; exit 66; }
[ -f "$candidate" ] || { echo "Candidate public API not found: $candidate" >&2; exit 66; }

temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/xceasy-api-compare.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT

normalize() {
    input=$1
    output=$2
    sed \
        -e '/^\/\/ swift-/d' \
        -e '/^import /d' \
        -e '/^[[:space:]]*$/d' \
        -e 's/^[[:space:]]*//' \
        -e 's/[[:space:]]*$//' \
        "$input" | LC_ALL=C sort > "$output"
}

normalize "$baseline" "$temporary_directory/baseline.txt"
normalize "$candidate" "$temporary_directory/candidate.txt"
comm -23 "$temporary_directory/baseline.txt" "$temporary_directory/candidate.txt" \
    > "$temporary_directory/removed.txt"

if [ -s "$temporary_directory/removed.txt" ]; then
    echo "Public API compatibility check failed. Removed or changed interface lines:" >&2
    sed -n '1,80p' "$temporary_directory/removed.txt" >&2
    exit 1
fi

baseline_lines=$(wc -l < "$temporary_directory/baseline.txt" | tr -d ' ')
candidate_lines=$(wc -l < "$temporary_directory/candidate.txt" | tr -d ' ')
echo "Public API is source-compatible with baseline: baseline_lines=$baseline_lines candidate_lines=$candidate_lines"
