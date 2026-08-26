#!/bin/sh
set -eu

repository_root=$(cd "$(dirname "$0")/../.." && pwd)
temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"' EXIT

printf 'redacted evidence\n' > "$temporary_directory/evidence.txt"
bytes=$(wc -c < "$temporary_directory/evidence.txt" | tr -d ' ')
sha=$(shasum -a 256 "$temporary_directory/evidence.txt" | awk '{print $1}')
jq -n --arg sha "$sha" --argjson bytes "$bytes" '{
    schemaVersion: "1.0.0",
    testId: "test-id",
    executionId: "execution-id",
    runId: "run-id",
    deviceId: "device-id",
    attempt: 1,
    frameworkVersion: "0.1.0",
    locale: "en",
    timezone: "UTC",
    git: {commit: null, dirty: null},
    artifacts: [{
        id: "artifact-id", path: "evidence.txt", kind: "log", mimeType: "text/plain",
        bytes: $bytes, sha256: $sha, producerEventId: "event-id", truncated: false,
        privacy: {redacted: true, ruleset: "default-v1"}
    }]
}' > "$temporary_directory/execution_diagnostic-manifest.json"

"$repository_root/scripts/validate-diagnostic-bundle.sh" \
    "$temporary_directory/execution_diagnostic-manifest.json" "secret-canary" >/dev/null

printf 'changed\n' >> "$temporary_directory/evidence.txt"
if "$repository_root/scripts/validate-diagnostic-bundle.sh" \
    "$temporary_directory/execution_diagnostic-manifest.json" >/dev/null 2>&1; then
    echo "Corrupted diagnostic bundle unexpectedly passed validation" >&2
    exit 1
fi

echo "Diagnostic bundle integrity contract tests passed"
