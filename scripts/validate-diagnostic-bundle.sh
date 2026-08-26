#!/bin/sh
set -eu

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 <diagnostic-manifest.json> [forbidden-canary]" >&2
    exit 64
fi

manifest=$1
forbidden_canary=${2:-}
[ -f "$manifest" ] || { echo "Diagnostic manifest not found: $manifest" >&2; exit 66; }
directory=$(dirname "$manifest")

jq -e '
    .schemaVersion == "1.0.0" and
    (.testId | type == "string" and length > 0) and
    (.executionId | type == "string" and length > 0) and
    (.attempt | type == "number" and . >= 1) and
    (.frameworkVersion | type == "string" and length > 0) and
    (.artifacts | type == "array") and
    all(.artifacts[];
        (.id | type == "string" and length > 0) and
        (.path | type == "string" and length > 0 and (contains("/") | not) and (contains("\\") | not)) and
        (.bytes | type == "number" and . >= 0) and
        (.sha256 | test("^[a-f0-9]{64}$")) and
        (.privacy.redacted == true)
    )
' "$manifest" >/dev/null

if [ -n "$forbidden_canary" ] && grep -R -Fq -- "$forbidden_canary" "$directory"; then
    echo "Forbidden canary found in diagnostic bundle" >&2
    exit 65
fi

jq -c '.artifacts[]' "$manifest" | while IFS= read -r artifact; do
    path=$(printf '%s' "$artifact" | jq -r '.path')
    expected_bytes=$(printf '%s' "$artifact" | jq -r '.bytes')
    expected_sha=$(printf '%s' "$artifact" | jq -r '.sha256')
    file="$directory/$path"
    [ -f "$file" ] || { echo "Missing diagnostic artifact: $path" >&2; exit 65; }
    actual_bytes=$(wc -c < "$file" | tr -d ' ')
    [ "$actual_bytes" = "$expected_bytes" ] || {
        echo "Diagnostic artifact size mismatch: $path" >&2
        exit 65
    }
    actual_sha=$(shasum -a 256 "$file" | awk '{print $1}')
    [ "$actual_sha" = "$expected_sha" ] || {
        echo "Diagnostic artifact digest mismatch: $path" >&2
        exit 65
    }
done

echo "Validated $(jq '.artifacts | length' "$manifest") diagnostic artifact(s)"
