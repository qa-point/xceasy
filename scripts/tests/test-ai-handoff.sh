#!/bin/sh
set -eu

repository_root=$(cd "$(dirname "$0")/../.." && pwd)
temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"' EXIT
events="$temporary_directory/events.jsonl"

jq -c '
    if .event == "ui.query.resolved" then
      .event = "ui.query.failed" |
      .level = "error" |
      .statusCode = "failed" |
      .reasonCode = "query.element_absent" |
      .queryEvidence.matched = false |
      .queryEvidence.candidateCollection = "bounded" |
      .queryEvidence.candidateCount = 1 |
      .queryEvidence.candidates = [{
        relationship: "alternative", elementType: "button", identifier: "promo.close.v2",
        label: "", labelLength: 0, frame: {x: 1, y: 2, width: 3, height: 4},
        isEnabled: true, isSelected: false, isHittable: true
      }]
    else . end
' "$repository_root/XCEasy/Tests/Fixtures/diagnostic-query-events.jsonl" > "$events"

"$repository_root/scripts/build-ai-handoff.sh" "$events" "$temporary_directory/handoff" suggest >/dev/null
jq -e '
    length == 1 and .[0].disposition == "suggested" and
    .[0].requiresHumanApproval == true and
    .[0].rankedCandidates[0].identifier == "promo.close.v2"
' "$temporary_directory/handoff/healing-proposals.json" >/dev/null
jq -e '.unverifiedGaps | length > 0' "$temporary_directory/handoff/test-generation-request.json" >/dev/null

if "$repository_root/scripts/build-ai-handoff.sh" \
    "$events" "$temporary_directory/rejected" suggest "promo.close.v2" >/dev/null 2>&1; then
    echo "AI handoff containing a forbidden canary unexpectedly passed" >&2
    exit 1
fi

echo "AI healing and test-generation handoff contract tests passed"
