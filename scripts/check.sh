#!/bin/sh
set -eu

mode=${1:-all}
case "$mode" in contracts|package|unit|race|fixture|coverage|release|all) ;; *)
    echo "Usage: $0 [contracts|package|unit|race|fixture|coverage|release|all]" >&2
    exit 64
esac

repository_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$repository_root"
. "$repository_root/scripts/lib/environment.sh"

resolve_xcode_developer_dir
unit_result_bundle=${XC_EASY_UNIT_RESULT_BUNDLE:-/private/tmp/xceasy-unit-$$.xcresult}
fixture_result_bundle=${XC_EASY_FIXTURE_RESULT_BUNDLE:-/private/tmp/xceasy-fixture-$$.xcresult}

run_contracts() {
    "$repository_root/scripts/validate-docs.sh"
    "$repository_root/scripts/validate-swift-documentation.sh"
    for test_script in "$repository_root"/scripts/tests/test-*.sh; do
        sh "$test_script"
    done
    jq empty "$repository_root/xceasy.toolchain.json"
    swift package dump-package >/dev/null
    swift test --package-path "$repository_root/XCEasyMacroPlugin"
}

run_package() {
    developer_dir=$DEVELOPER_DIR
    if [ -n "${XC_EASY_PACKAGE_DERIVED_DATA:-}" ]; then
        derived_data=$XC_EASY_PACKAGE_DERIVED_DATA
        remove_derived_data=false
    else
        derived_data=/private/tmp/xceasy-package-derived-$$
        remove_derived_data=true
    fi
    package_checkout=$(mktemp -d "${TMPDIR:-/tmp}/xceasy-package.XXXXXX")
    cp "$repository_root/Package.swift" "$package_checkout/Package.swift"
    if [ -f "$repository_root/Package.resolved" ]; then
        cp "$repository_root/Package.resolved" "$package_checkout/Package.resolved"
    fi
    mkdir -p "$package_checkout/XCEasy"
    cp -R "$repository_root/XCEasy/Sources" "$package_checkout/XCEasy/Sources"
    cp -R "$repository_root/XCEasy/Resources" "$package_checkout/XCEasy/Resources"
    cp -R "$repository_root/XCEasy/Tests" "$package_checkout/XCEasy/Tests"
    cp -R "$repository_root/XCEasyMacroPlugin" "$package_checkout/XCEasyMacroPlugin"
    (
        cd "$package_checkout"
        DEVELOPER_DIR="$developer_dir" xcodebuild build \
            -scheme XCEasy \
            -destination 'generic/platform=iOS Simulator' \
            -derivedDataPath "$derived_data"
    )
    rm -rf "$package_checkout"
    if [ "$remove_derived_data" = "true" ]; then
        rm -rf "$derived_data"
    fi
}

simulator_destination() {
    device_id=${XC_EASY_TEST_DEVICE_ID:-}
    if [ -z "$device_id" ]; then
        device_id=$(xcrun simctl list devices available -j |
            jq -r '[.devices[][] | select(.name == "iPhone 17 Pro")][0].udid // empty')
    fi
    [ -n "$device_id" ] || { echo "No available iPhone 17 Pro simulator" >&2; exit 69; }
    printf 'platform=iOS Simulator,id=%s\n' "$device_id"
}

run_unit() {
    run_tuist generate --no-open
    xcodebuild test \
        -workspace XCEasy.xcworkspace \
        -scheme XCEasy \
        -destination "$(simulator_destination)" \
        -only-testing:XCEasyTests \
        -enableCodeCoverage YES \
        -resultBundlePath "$unit_result_bundle"
}

run_race() {
    race_result_bundle=${XC_EASY_RACE_RESULT_BUNDLE:-/private/tmp/xceasy-race-$$.xcresult}
    run_tuist generate --no-open
    xcodebuild test \
        -workspace XCEasy.xcworkspace \
        -scheme XCEasy \
        -destination "$(simulator_destination)" \
        -only-testing:XCEasyTests/XCEasyExecutionContextTests \
        -only-testing:XCEasyTests/XCEasyComponentTests \
        -only-testing:XCEasyTests/XCEasySoftAssertionsTests \
        -only-testing:XCEasyTests/DiagnosticsTests \
        -only-testing:XCEasyTests/CoreUtilitiesTests \
        -enableThreadSanitizer YES \
        -enableCodeCoverage NO \
        -resultBundlePath "$race_result_bundle"
}

run_fixture() {
    (
        cd XCEasyIntegrationFixture
        run_tuist install
        run_tuist generate --no-open
    )
    xcodebuild test \
        -workspace XCEasyIntegrationFixture/XCEasyIntegrationFixture.xcworkspace \
        -scheme XCEasyIntegrationFixture \
        -destination "$(simulator_destination)" \
        -only-testing:XCEasyIntegrationFixtureUITests \
        -enableCodeCoverage YES \
        -resultBundlePath "$fixture_result_bundle"
}

run_coverage() {
    "$repository_root/scripts/validate-code-coverage.sh" \
        "$unit_result_bundle" \
        "$fixture_result_bundle"
}

run_release() {
    "$repository_root/scripts/validate-release.sh"
}

case "$mode" in
    contracts) run_contracts ;;
    package) run_package ;;
    unit) run_unit ;;
    race) run_race ;;
    fixture) run_fixture ;;
    coverage) run_coverage ;;
    release) run_release ;;
    all) run_contracts; run_package; run_unit; run_race; run_fixture; run_coverage; run_release ;;
esac
