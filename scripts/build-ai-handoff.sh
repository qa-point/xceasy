#!/bin/sh
set -eu

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <events.jsonl> <output-directory> [observe|suggest] [forbidden-canary]" >&2
    exit 64
fi

events=$1
output=$2
mode=${3:-observe}
forbidden_canary=${4:-}
case "$mode" in observe|suggest) ;; *) echo "Unsupported healing mode: $mode" >&2; exit 64 ;; esac

script_directory=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
"$script_directory/validate-diagnostic-events.sh" "$events" "$forbidden_canary" >/dev/null
mkdir -p "$output"
temporary_events=$(mktemp)
trap 'rm -f "$temporary_events"' EXIT
jq -s '.' "$events" > "$temporary_events"

jq --arg mode "$mode" '
    [ .[] | select(.event == "ui.query.failed") |
      (.queryEvidence.candidates // []) as $candidates |
      {
        schemaVersion: "1.0.0",
        proposalId: ((.executionId // "unknown") + ":" + (.operationId // "unknown")),
        executionId: (.executionId // "unknown"),
        testId: (.testId // "unknown"),
        failureEventId: (.operationId // "unknown"),
        selectorFingerprint: .selector.fingerprint,
        disposition: (
          if ($candidates | length) == 0 then "blocked"
          elif ($candidates | length) > 1 then "blocked"
          elif $mode == "observe" then "observed"
          else "suggested" end
        ),
        reasonCode: (
          if ($candidates | length) == 0 then "healing.no_candidate_evidence"
          elif ($candidates | length) > 1 then "healing.ambiguous_candidates"
          elif $mode == "observe" then "healing.policy_observe"
          else "healing.candidate_ready_for_review" end
        ),
        requiresHumanApproval: true,
        rankedCandidates: [
          $candidates | to_entries[] | {
            evidenceCandidateIndex: .key,
            identifier: .value.identifier,
            elementType: .value.elementType,
            confidence: (if .value.isHittable and .value.isEnabled then 0.9 else 0.75 end),
            reasonCodes: (["healing.evidence_candidate"] +
              (if .value.isHittable then ["healing.candidate_hittable"] else [] end) +
              (if .value.isEnabled then ["healing.candidate_enabled"] else [] end))
          }
        ],
        verification: {
          required: true,
          commands: ["failed test", "related selector contract tests", "original environment rerun"],
          originalFailureMustRemainLinked: true
        }
      }
    ]
' "$temporary_events" > "$output/healing-proposals.json"

jq '
    {
      schemaVersion: "1.0.0",
      testId: ([.[] | .testId // empty][0] // "unknown"),
      executionId: ([.[] | .executionId // empty][0] // "unknown"),
      semanticJourney: [
        .[] |
        select((.event == "operation.finished" or .event == "step.finished") and .operationCode != null) |
        {
          evidenceEventId: (.operationId // "unknown"),
          parentEventId: (.parentOperationId // null),
          operation: .operationCode,
          target: (.target // null),
          outcome: (.statusCode // "unknown"),
          reasonCode: (.reasonCode // null),
          durationMilliseconds: (.durationMilliseconds // null),
          source: (.source // null)
        }
      ],
      observableFailures: [
        .[] | select(.statusCode == "failed") |
        {evidenceEventId: (.operationId // "unknown"), event: .event, reasonCode: (.reasonCode // "unknown")}
      ],
      constraints: {
        style: "XCEasy project constitution and code style",
        architecture: "reusable component POM with lazy locators",
        selectors: "stable accessibility identifiers; coordinate/index only as marked fallback",
        assertions: "must cite an observable outcome",
        verification: ["compile", "unit tests", "targeted UI test", "diagnostic schema validation"]
      },
      assumptions: ["The event stream is complete for one test execution."],
      unverifiedGaps: ["Business intent must be confirmed by a human before generated assertions are accepted."],
      confidence: (if ([.[] | select(.event == "test.finished")] | length) == 1 then 0.9 else 0.5 end)
    }
' "$temporary_events" > "$output/test-generation-request.json"

test_id=$(jq -r '[.[] | .testId // empty][0] // "unknown"' "$temporary_events")
execution_id=$(jq -r '[.[] | .executionId // empty][0] // "unknown"' "$temporary_events")
failure_count=$(jq '[.[] | select(.statusCode == "failed")] | length' "$temporary_events")
{
    printf '# XCEasy AI handoff\n\n'
    printf '%s\n' "- Test ID: \`$test_id\`"
    printf '%s\n' "- Execution ID: \`$execution_id\`"
    printf '%s\n' "- Failed events: $failure_count"
    printf '%s\n\n' "- Healing policy: \`$mode\`"
    printf '%s\n' 'Use event and attachment IDs as evidence. Do not change expected business behavior or accept a healing proposal without the verification commands listed in the JSON artifacts.'
} > "$output/reproduction.md"

"$script_directory/validate-ai-handoff.sh" "$output" "$forbidden_canary" >/dev/null
echo "AI handoff written to $output"
