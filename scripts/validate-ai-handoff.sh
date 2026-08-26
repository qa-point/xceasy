#!/bin/sh
set -eu

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 <handoff-directory> [forbidden-canary]" >&2
    exit 64
fi
directory=$1
forbidden_canary=${2:-}

for file in healing-proposals.json test-generation-request.json reproduction.md; do
    [ -f "$directory/$file" ] || { echo "Missing AI handoff artifact: $file" >&2; exit 66; }
done
if [ -n "$forbidden_canary" ] && grep -R -Fq -- "$forbidden_canary" "$directory"; then
    echo "Forbidden canary found in AI handoff" >&2
    exit 65
fi

jq -e '
    type == "array" and all(.[];
        .schemaVersion == "1.0.0" and
        (.proposalId | type == "string" and length > 0) and
        (.disposition == "blocked" or .disposition == "observed" or .disposition == "suggested") and
        (.reasonCode | type == "string" and length > 0) and
        .requiresHumanApproval == true and
        .verification.required == true and
        .verification.originalFailureMustRemainLinked == true
    )
' "$directory/healing-proposals.json" >/dev/null
jq -e '
    .schemaVersion == "1.0.0" and
    (.semanticJourney | type == "array") and
    (.observableFailures | type == "array") and
    (.assumptions | type == "array" and length > 0) and
    (.unverifiedGaps | type == "array" and length > 0) and
    (.confidence | type == "number" and . >= 0 and . <= 1)
' "$directory/test-generation-request.json" >/dev/null

echo "Validated AI handoff in $directory"
