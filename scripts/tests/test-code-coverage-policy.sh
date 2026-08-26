#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
fixture_directory=$(mktemp -d "${TMPDIR:-/tmp}/xceasy-coverage-policy.XXXXXX")
trap 'rm -rf "$fixture_directory"' EXIT HUP INT TERM

write_report() {
    target_coverage=$1
    identity_coverage=$2
    cat >"$fixture_directory/report.json" <<EOF
{
  "targets": [{
    "name": "XCEasy.framework",
    "lineCoverage": $target_coverage,
    "coveredLines": 60,
    "executableLines": 100,
    "files": [{
      "name": "AllureIdentity.swift",
      "lineCoverage": $identity_coverage,
      "coveredLines": 10,
      "executableLines": 10
    }]
  }]
}
EOF
}

cat >"$fixture_directory/policy.json" <<'EOF'
{
  "target": "XCEasy.framework",
  "minimumLineCoverage": 0.60,
  "criticalFiles": [{
    "name": "AllureIdentity.swift",
    "minimumLineCoverage": 1.0
  }]
}
EOF

write_report 0.60 1.0
"$repository_root/scripts/evaluate-code-coverage.sh" \
    "$fixture_directory/report.json" \
    "$fixture_directory/policy.json" \
    "$fixture_directory/summary.json" >/dev/null
jq -e '.passed == true' "$fixture_directory/summary.json" >/dev/null

write_report 0.59 1.0
if "$repository_root/scripts/evaluate-code-coverage.sh" \
    "$fixture_directory/report.json" \
    "$fixture_directory/policy.json" \
    "$fixture_directory/summary.json" >/dev/null 2>&1; then
    echo "Coverage evaluator accepted target coverage below the threshold" >&2
    exit 1
fi

write_report 0.80 0.99
if "$repository_root/scripts/evaluate-code-coverage.sh" \
    "$fixture_directory/report.json" \
    "$fixture_directory/policy.json" \
    "$fixture_directory/summary.json" >/dev/null 2>&1; then
    echo "Coverage evaluator accepted a critical file below the threshold" >&2
    exit 1
fi

cat >"$fixture_directory/report.json" <<'EOF'
{"targets": []}
EOF
if "$repository_root/scripts/evaluate-code-coverage.sh" \
    "$fixture_directory/report.json" \
    "$fixture_directory/policy.json" \
    "$fixture_directory/summary.json" >/dev/null 2>&1; then
    echo "Coverage evaluator accepted a missing target" >&2
    exit 1
fi

echo "Code coverage policy contract tests passed."
