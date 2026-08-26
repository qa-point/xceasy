#!/bin/sh
set -eu

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 <events.jsonl> [forbidden-canary]" >&2
    exit 64
fi

events=$1
forbidden_canary=${2:-}
if [ ! -f "$events" ]; then
    echo "Diagnostic event stream not found: $events" >&2
    exit 66
fi
if [ -n "$forbidden_canary" ] && grep -Fq "$forbidden_canary" "$events"; then
    echo "Forbidden canary found in diagnostic events" >&2
    exit 65
fi

event_count=0
query_count=0
collection_count=0
while IFS= read -r event; do
    [ -n "$event" ] || continue
    event_count=$((event_count + 1))
    printf '%s' "$event" | jq -e '
        .schemaVersion == "1.0.0" and
        (.timestamp | type == "string" and length > 0) and
        (.monotonicNanoseconds | type == "number" and . >= 0) and
        (.event | type == "string" and length > 0) and
        (.level == "debug" or .level == "info" or .level == "warning" or .level == "error") and
        (.processId | type == "number" and . >= 0) and
        (.threadId | type == "string" and length > 0) and
        (.privacy.redacted == true) and
        (.privacy.ruleset | type == "string" and length > 0) and
        (if has("durationMilliseconds") then (.durationMilliseconds | type == "number" and . >= 0) else true end) and
        (if has("selector") then
            (.selector.fingerprint | test("^[a-f0-9]{64}$")) and
            (.selector.fingerprintConfidence == "exact" or .selector.fingerprintConfidence == "privacy_reduced") and
            (.selector.segments | type == "array" and length > 0) and
            all(.selector.segments[];
                (.elementType | type == "string" and length > 0) and
                (.strategy == "any" or .strategy == "identifier" or .strategy == "predicate" or .strategy == "text") and
                (.isValueRedacted | type == "boolean") and
                (if has("valueLength") then (.valueLength | type == "number" and . >= 0) else true end) and
                (if has("index") then (.index | type == "number") else true end) and
                (if has("selection") then (.selection == "first" or .selection == "last" or .selection == "index") else true end)
            ) and
            (if any(.selector.segments[]; .isValueRedacted == true)
             then .selector.fingerprintConfidence == "privacy_reduced"
             else .selector.fingerprintConfidence == "exact" end)
         else true end) and
        (if has("collectionEvidence") then
            (.collectionEvidence.expectation | type == "string" and length > 0) and
            (.collectionEvidence.matched | type == "boolean") and
            (.collectionEvidence.attempts | type == "number" and . >= 0) and
            (.collectionEvidence.elapsedMilliseconds | type == "number" and . >= 0) and
            (if .collectionEvidence | has("expectedCount") then (.collectionEvidence.expectedCount | type == "number") else true end) and
            (if .collectionEvidence | has("actualCount") then (.collectionEvidence.actualCount | type == "number" and . >= 0) else true end) and
            (if .collectionEvidence | has("selectedPosition") then
                (.collectionEvidence.selectedPosition == "first" or
                 .collectionEvidence.selectedPosition == "last" or
                 .collectionEvidence.selectedPosition == "index" or
                 .collectionEvidence.selectedPosition == "range")
             else true end) and
            (if .collectionEvidence | has("selectedIndices") then
                (.collectionEvidence.selectedIndices | type == "array" and length <= 100) and
                all(.collectionEvidence.selectedIndices[]; type == "number")
             else true end) and
            (if .collectionEvidence | has("failedIndices") then
                (.collectionEvidence.failedIndices | type == "array" and length <= 100) and
                all(.collectionEvidence.failedIndices[]; type == "number" and . >= 0)
             else true end) and
            (if .collectionEvidence | has("observations") then
                (.collectionEvidence.observations | type == "array" and length <= 50) and
                all(.collectionEvidence.observations[];
                    (.attempt | type == "number" and . >= 1) and
                    (.elapsedMilliseconds | type == "number" and . >= 0) and
                    (.count | type == "number" and . >= 0) and
                    (.isContextAvailable | type == "boolean") and
                    (if has("displayedCount") then (.displayedCount | type == "number" and . >= 0) else true end) and
                    (if has("failedIndices") then
                        (.failedIndices | type == "array" and length <= 100) and
                        all(.failedIndices[]; type == "number" and . >= 0)
                     else true end)
                )
             else true end)
         else true end) and
        (if has("source") then
            (.source.file | type == "string" and length > 0 and (contains("/") | not) and (contains("\\") | not)) and
            (.source.line | type == "number" and . >= 0)
         else true end) and
        (if has("attachments") then
            (.attachments | type == "array" and length <= 20) and
            all(.attachments[];
                (.id | type == "string" and length > 0) and
                (.path | type == "string" and length > 0 and (contains("/") | not) and (contains("\\") | not)) and
                (.mimeType | type == "string" and length > 0) and
                (.kind | type == "string" and length > 0) and
                (.truncated | type == "boolean")
            )
         else true end) and
        (if has("performance") then
            (.performance.operationKey | type == "string" and length > 0) and
            (.performance.phasesMilliseconds | type == "object") and
            all(.performance.phasesMilliseconds[]; type == "number" and . >= 0) and
            (if .performance | has("budgetMilliseconds") then (.performance.budgetMilliseconds | type == "number" and . >= 0) else true end) and
            (if .performance | has("budgetStatus") then (.performance.budgetStatus == "within_budget" or .performance.budgetStatus == "exceeded") else true end)
         else true end) and
        (if has("queryEvidence") then
            (.queryEvidence.expectedState | type == "string" and length > 0) and
            (.queryEvidence.initialState | type == "string" and length > 0) and
            (.queryEvidence.finalState | type == "string" and length > 0) and
            (.queryEvidence.evidenceLevel == "basic" or .queryEvidence.evidenceLevel == "detailed") and
            (.queryEvidence.candidateCollection == "omitted_by_policy" or .queryEvidence.candidateCollection == "bounded") and
            (.queryEvidence.matched | type == "boolean") and
            (.queryEvidence.reasonCode | type == "string" and length > 0) and
            (.queryEvidence.attempts | type == "number" and . >= 1) and
            (.queryEvidence.elapsedMilliseconds | type == "number" and . >= 0) and
            (.queryEvidence.candidateCount | type == "number" and . >= 0) and
            (.queryEvidence.candidates | type == "array" and length <= 5) and
            (if .queryEvidence | has("observations") then
                (.queryEvidence.observations | type == "array" and length <= 50) and
                all(.queryEvidence.observations[];
                    (.attempt | type == "number" and . >= 1) and
                    (.elapsedMilliseconds | type == "number" and . >= 0) and
                    (.state == "absent" or .state == "hidden" or .state == "visible" or .state == "hittable") and
                    (.exists | type == "boolean") and
                    (.isHittable | type == "boolean")
                )
             else true end) and
            all(.queryEvidence.candidates[];
                (.relationship == "matched" or .relationship == "alternative") and
                (.elementType | type == "string" and length > 0) and
                (.identifier | type == "string") and
                (.label == "" or .label == "<redacted:label>") and
                (.labelLength | type == "number" and . >= 0) and
                (if has("value") then .value == "<redacted:value>" else true end) and
                (if has("valueLength") then (.valueLength | type == "number" and . >= 0) else true end) and
                (.isEnabled | type == "boolean") and
                (.isSelected | type == "boolean") and
                (.isHittable | type == "boolean")
            ) and
            (if .queryEvidence.candidateCollection == "omitted_by_policy"
             then (.queryEvidence.candidates | length == 0)
             else true end) and
            (if .queryEvidence.evidenceLevel == "detailed"
             then .queryEvidence.candidateCollection == "bounded"
             else true end)
         else true end) and
        (if (.event == "ui.query.resolved" or .event == "ui.query.failed") then
            has("selector") and has("queryEvidence") and
            (.testId | type == "string" and length > 0) and
            (.executionId | type == "string" and length > 0) and
            (.operationId | type == "string" and length > 0) and
            (.reasonCode == .queryEvidence.reasonCode)
         else true end) and
        (if .event == "ui.collection.finished" then
            has("selector") and has("collectionEvidence") and
            (.operationId | type == "string" and length > 0) and
            (.operationCode | type == "string" and startswith("component.collection.")) and
            (.durationMilliseconds == .collectionEvidence.elapsedMilliseconds)
         else true end)
    ' >/dev/null
    case "$(printf '%s' "$event" | jq -r '.event')" in
        ui.query.resolved|ui.query.failed) query_count=$((query_count + 1)) ;;
        ui.collection.finished) collection_count=$((collection_count + 1)) ;;
    esac
done < "$events"

if [ "$event_count" -eq 0 ]; then
    echo "Diagnostic event stream is empty" >&2
    exit 65
fi

echo "Validated $event_count diagnostic event(s) for schema 1.0.0, including $query_count completed UI query event(s) and $collection_count completed collection event(s)"
