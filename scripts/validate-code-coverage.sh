#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <unit.xcresult> <fixture.xcresult>" >&2
    exit 64
fi

unit_result=$1
fixture_result=$2
repository_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
policy=${XC_EASY_COVERAGE_POLICY:-$repository_root/scripts/coverage-policy.json}
report_json=${XC_EASY_COVERAGE_REPORT_JSON:-/private/tmp/xceasy-coverage-report.json}
summary_json=${XC_EASY_COVERAGE_SUMMARY:-/private/tmp/xceasy-coverage-summary.json}

[ -d "$unit_result" ] || { echo "Unit result bundle not found: $unit_result" >&2; exit 66; }
[ -d "$fixture_result" ] || { echo "Fixture result bundle not found: $fixture_result" >&2; exit 66; }

coverage_directory=$(mktemp -d "${TMPDIR:-/tmp}/xceasy-coverage.XXXXXX")
trap 'rm -rf "$coverage_directory"' EXIT HUP INT TERM

xcrun xcresulttool export coverage --path "$unit_result" --output-path "$coverage_directory/unit"
xcrun xcresulttool export coverage --path "$fixture_result" --output-path "$coverage_directory/fixture"

unit_report=$(find "$coverage_directory/unit" -maxdepth 1 -type f -name '*CoverageReport' -print -quit)
unit_archive=$(find "$coverage_directory/unit" -maxdepth 1 -type d -name '*CoverageArchive' -print -quit)
fixture_report=$(find "$coverage_directory/fixture" -maxdepth 1 -type f -name '*CoverageReport' -print -quit)
fixture_archive=$(find "$coverage_directory/fixture" -maxdepth 1 -type d -name '*CoverageArchive' -print -quit)

[ -n "$unit_report" ] && [ -n "$unit_archive" ] || {
    echo "Unit result bundle contains no exported coverage report/archive" >&2
    exit 65
}
[ -n "$fixture_report" ] && [ -n "$fixture_archive" ] || {
    echo "Fixture result bundle contains no exported coverage report/archive" >&2
    exit 65
}

xcrun xccov merge \
    "$unit_report" "$unit_archive" \
    "$fixture_report" "$fixture_archive" \
    --outReport "$coverage_directory/merged.xccovreport" \
    --outArchive "$coverage_directory/merged.xccovarchive"
xcrun xccov view --report --json "$coverage_directory/merged.xccovreport" >"$report_json"

"$repository_root/scripts/evaluate-code-coverage.sh" "$report_json" "$policy" "$summary_json"
