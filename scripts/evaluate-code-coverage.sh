#!/bin/sh
set -eu

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <xccov-report.json> <coverage-policy.json> [summary.json]" >&2
    exit 64
fi

report_json=$1
policy_json=$2
summary_json=${3:-/private/tmp/xceasy-coverage-summary.json}

[ -f "$report_json" ] || { echo "Coverage report not found: $report_json" >&2; exit 66; }
[ -f "$policy_json" ] || { echo "Coverage policy not found: $policy_json" >&2; exit 66; }
jq empty "$report_json"
jq empty "$policy_json"

target_name=$(jq -r '.target // empty' "$policy_json")
[ -n "$target_name" ] || { echo "Coverage policy has no target" >&2; exit 65; }

jq --arg target_name "$target_name" --slurpfile policy "$policy_json" '
    [.targets[] | select(.name == $target_name)] | first as $target
    | if $target == null then
        {
            target: $target_name,
            found: false,
            passed: false,
            reason: "target_not_found",
            criticalFiles: []
        }
      else
        [
            $policy[0].criticalFiles[] as $rule
            | ([$target.files[] | select(.name == $rule.name)] | first) as $file
            | {
                name: $rule.name,
                minimumLineCoverage: $rule.minimumLineCoverage,
                found: ($file != null),
                lineCoverage: ($file.lineCoverage // 0),
                coveredLines: ($file.coveredLines // 0),
                executableLines: ($file.executableLines // 0),
                passed: ($file != null and $file.lineCoverage >= $rule.minimumLineCoverage)
              }
        ] as $critical
        | {
            target: $target.name,
            found: true,
            minimumLineCoverage: $policy[0].minimumLineCoverage,
            lineCoverage: $target.lineCoverage,
            coveredLines: $target.coveredLines,
            executableLines: $target.executableLines,
            criticalFiles: $critical,
            passed: (
                $target.lineCoverage >= $policy[0].minimumLineCoverage
                and ($critical | all(.passed))
            )
          }
      end
' "$report_json" >"$summary_json"

jq -r '
    if .found then
        "Coverage \(.target): \(.coveredLines)/\(.executableLines) lines (\((.lineCoverage * 10000 | round) / 100)%), minimum \((.minimumLineCoverage * 10000 | round) / 100)%"
    else
        "Coverage target not found: \(.target)"
    end
' "$summary_json"
jq -r '.criticalFiles[] | "  \(.name): \(.coveredLines)/\(.executableLines) (\((.lineCoverage * 10000 | round) / 100)%), minimum \((.minimumLineCoverage * 10000 | round) / 100)% — \(if .passed then "passed" else "failed" end)"' "$summary_json"

if ! jq -e '.passed == true' "$summary_json" >/dev/null; then
    echo "Code coverage policy failed. Machine-readable summary: $summary_json" >&2
    exit 1
fi

echo "Code coverage policy passed. Machine-readable summary: $summary_json"
