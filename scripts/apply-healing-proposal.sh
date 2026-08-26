#!/bin/sh
set -eu

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <source-bundle> <approval.json> <repository-root> [--apply]" >&2
    exit 64
fi

source_bundle=$(cd "$1" && pwd)
approval=$2
repository_root=$(cd "$3" && pwd -P)
mode=${4:-}
case "$mode" in ""|--apply) ;; *) echo "Unknown option: $mode" >&2; exit 64 ;; esac

manifest="$source_bundle/source-manifest.json"
proposals="$source_bundle/healing-proposals.json"
[ -f "$manifest" ] || { echo "Source manifest not found" >&2; exit 66; }
[ -f "$proposals" ] || { echo "Healing proposals not found" >&2; exit 66; }
jq -e '
    .schemaVersion == "1.0.0" and
    .decision == "approved" and
    (.proposalId | type == "string" and length > 0) and
    (.approvedBy | type == "string" and length > 0) and
    (.approvedAt | type == "string" and length > 0) and
    (.sourceFile | type == "string" and endswith(".swift")) and
    (.sourceSHA256 | type == "string" and test("^[a-f0-9]{64}$")) and
    (.expectedIdentifier | type == "string" and test("^[A-Za-z0-9_.:-]+$")) and
    (.candidateIdentifier | type == "string" and test("^[A-Za-z0-9_.:-]+$")) and
    (.verificationProfile == "package" or .verificationProfile == "unit" or .verificationProfile == "integration" or .verificationProfile == "all" or .verificationProfile == "fixture")
' "$approval" >/dev/null

proposal_id=$(jq -r '.proposalId' "$approval")
source_file=$(jq -r '.sourceFile' "$approval")
source_sha256=$(jq -r '.sourceSHA256' "$approval")
expected_identifier=$(jq -r '.expectedIdentifier' "$approval")
candidate_identifier=$(jq -r '.candidateIdentifier' "$approval")
verification_profile=$(jq -r '.verificationProfile' "$approval")

jq -e --arg proposal_id "$proposal_id" --arg candidate "$candidate_identifier" '
    any(.[];
        .proposalId == $proposal_id and
        .disposition == "suggested" and
        .requiresHumanApproval == true and
        any(.rankedCandidates[]; .identifier == $candidate)
    )
' "$proposals" >/dev/null
jq -e --arg proposal_id "$proposal_id" --arg path "$source_file" --arg sha "$source_sha256" '
    .proposalId == $proposal_id and
    any(.sources[]; .path == $path and .sha256 == $sha)
' "$manifest" >/dev/null

case "$source_file" in
    /*|../*|*/../*|*/..|..|*//*|*\\*) echo "Unsafe source path: $source_file" >&2; exit 65 ;;
esac
source="$repository_root/$source_file"
[ -f "$source" ] || { echo "Approved source file not found: $source_file" >&2; exit 66; }
[ ! -L "$source" ] || { echo "Symlinked source files cannot be patched" >&2; exit 65; }
resolved_source_directory=$(cd "$(dirname "$source")" && pwd -P)
case "$resolved_source_directory/$(basename "$source")" in
    "$repository_root"/*) ;;
    *) echo "Approved source escapes repository root: $source_file" >&2; exit 65 ;;
esac
current_sha256=$(shasum -a 256 "$source" | awk '{print $1}')
[ "$current_sha256" = "$source_sha256" ] || {
    echo "Approved source changed after review: $source_file" >&2
    exit 65
}

old_literal="\"$expected_identifier\""
new_literal="\"$candidate_identifier\""
occurrences=$(awk -v needle="$old_literal" '
    { line = $0; while ((position = index(line, needle)) > 0) { count += 1; line = substr(line, position + length(needle)) } }
    END { print count + 0 }
' "$source")
[ "$occurrences" -eq 1 ] || {
    echo "Expected exactly one approved selector literal, found $occurrences" >&2
    exit 65
}

temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/xceasy-healing-apply.XXXXXX")
cleanup() { rm -rf "$temporary_directory"; }
trap cleanup EXIT
candidate_source="$temporary_directory/candidate.swift"
awk -v old="$old_literal" -v new="$new_literal" '
    {
        position = index($0, old)
        if (position > 0) {
            print substr($0, 1, position - 1) new substr($0, position + length(old))
        } else {
            print
        }
    }
' "$source" > "$candidate_source"

patch_file="$source_bundle/healing.patch"
if diff -u --label "a/$source_file" --label "b/$source_file" "$source" "$candidate_source" > "$patch_file"; then
    echo "Approved selector replacement produced no diff" >&2
    exit 65
else
    diff_status=$?
    [ "$diff_status" -eq 1 ] || exit "$diff_status"
fi

report="$source_bundle/healing-application.json"
if [ -z "$mode" ]; then
    jq -n \
        --arg proposal_id "$proposal_id" \
        --arg source_file "$source_file" \
        --arg expected "$expected_identifier" \
        --arg candidate "$candidate_identifier" '
        {
            schemaVersion: "1.0.0",
            proposalId: $proposal_id,
            status: "prepared_for_review",
            sourceFile: $source_file,
            expectedIdentifier: $expected,
            candidateIdentifier: $candidate,
            patch: "healing.patch",
            sourceMutated: false
        }
    ' > "$report"
    echo "Healing patch prepared for review: $patch_file"
    exit 0
fi

if [ "$verification_profile" = "fixture" ] && [ "${XC_EASY_ALLOW_FIXTURE_HEALING:-false}" != "true" ]; then
    echo "Fixture verification profile is disabled outside isolated contract tests" >&2
    exit 65
fi

backup="$temporary_directory/original.swift"
cp "$source" "$backup"
cp "$candidate_source" "$source"
verification_status=0
case "$verification_profile" in
    fixture)
        verification_status=${XC_EASY_FIXTURE_VERIFICATION_STATUS:-0}
        ;;
    integration)
        if (cd "$repository_root" && ./scripts/check.sh fixture); then
            verification_status=0
        else
            verification_status=$?
        fi
        ;;
    package|unit|all)
        if (cd "$repository_root" && ./scripts/check.sh "$verification_profile"); then
            verification_status=0
        else
            verification_status=$?
        fi
        ;;
esac

if [ "$verification_status" -ne 0 ]; then
    cp "$backup" "$source"
    jq -n \
        --arg proposal_id "$proposal_id" \
        --arg source_file "$source_file" \
        --arg profile "$verification_profile" \
        --argjson verification_status "$verification_status" '
        {
            schemaVersion: "1.0.0",
            proposalId: $proposal_id,
            status: "verification_failed_rolled_back",
            sourceFile: $source_file,
            verificationProfile: $profile,
            verificationExitCode: $verification_status,
            sourceMutated: false
        }
    ' > "$report"
    echo "Healing verification failed and the source was restored" >&2
    exit "$verification_status"
fi

new_sha256=$(shasum -a 256 "$source" | awk '{print $1}')
jq -n \
    --arg proposal_id "$proposal_id" \
    --arg source_file "$source_file" \
    --arg profile "$verification_profile" \
    --arg before_sha256 "$source_sha256" \
    --arg after_sha256 "$new_sha256" '
    {
        schemaVersion: "1.0.0",
        proposalId: $proposal_id,
        status: "applied_and_verified",
        sourceFile: $source_file,
        verificationProfile: $profile,
        verificationExitCode: 0,
        beforeSHA256: $before_sha256,
        afterSHA256: $after_sha256,
        sourceMutated: true
    }
' > "$report"
echo "Healing proposal applied and verified: $source_file"
