#!/bin/sh
set -eu

repository_root=$(cd "$(dirname "$0")/../.." && pwd)
valid="$repository_root/XCEasy/Tests/Fixtures/diagnostic-query-events.jsonl"
invalid="$repository_root/XCEasy/Tests/Fixtures/diagnostic-query-events-invalid.jsonl"
schema="$repository_root/schemas/diagnostic-event-1.0.0.schema.json"

jq -e '
    ."$schema" == "https://json-schema.org/draft/2020-12/schema" and
    .properties.schemaVersion.const == "1.0.0" and
    (."$defs".queryEvidence.properties.candidates.maxItems == 5) and
    (."$defs".queryEvidence.required | index("evidenceLevel") != null) and
    (."$defs".queryEvidence.required | index("candidateCollection") != null) and
    (."$defs".queryEvidence.properties.observations.maxItems == 50) and
    (."$defs".collectionEvidence.properties.observations.maxItems == 50) and
    (."$defs".collectionEvidence.properties.selectedIndices.maxItems == 100) and
    (."$defs".selectorSegment.properties.selection.enum | index("last") != null) and
    (.required | index("privacy") != null) and
    (.required | index("processId") != null)
' "$schema" >/dev/null

"$repository_root/scripts/validate-diagnostic-events.sh" "$valid" "selector-canary" >/dev/null

if "$repository_root/scripts/validate-diagnostic-events.sh" "$invalid" >/dev/null 2>&1; then
    echo "Invalid diagnostic query evidence unexpectedly passed validation" >&2
    exit 1
fi

if "$repository_root/scripts/validate-diagnostic-events.sh" "$valid" "promo.close" >/dev/null 2>&1; then
    echo "Forbidden diagnostic canary unexpectedly passed validation" >&2
    exit 1
fi

echo "Diagnostic event 1.0.0 validation contract tests passed"
