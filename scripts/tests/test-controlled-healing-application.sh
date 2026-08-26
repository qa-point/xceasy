#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"' EXIT
fixture_repository="$temporary_directory/repository"
handoff="$temporary_directory/handoff"
bundle="$temporary_directory/source-bundle"
mkdir -p "$fixture_repository/Sources" "$handoff"

printf 'let banner = find(identifier: "promoBanner.old")\n' > "$fixture_repository/Sources/Banner.swift"
jq -n '[{
    schemaVersion: "1.0.0",
    proposalId: "proposal-1",
    disposition: "suggested",
    reasonCode: "healing.candidate_ready_for_review",
    requiresHumanApproval: true,
    rankedCandidates: [{identifier: "promoBanner.new", confidence: 0.95}],
    verification: {required: true, originalFailureMustRemainLinked: true}
}]' > "$handoff/healing-proposals.json"
jq -n '{
    schemaVersion: "1.0.0",
    semanticJourney: [],
    observableFailures: [],
    assumptions: ["fixture"],
    unverifiedGaps: ["human review"],
    confidence: 0.9
}' > "$handoff/test-generation-request.json"
printf '# Fixture reproduction\n' > "$handoff/reproduction.md"
jq -n '{
    schemaVersion: "1.0.0",
    proposalId: "proposal-1",
    sourceFiles: [{path: "Sources/Banner.swift", selectorIdentifier: "promoBanner.old"}]
}' > "$temporary_directory/source-map.json"

"$repository_root/scripts/build-healing-source-bundle.sh" \
    "$handoff" "$temporary_directory/source-map.json" "$fixture_repository" "$bundle" >/dev/null
source_sha256=$(jq -r '.sources[0].sha256' "$bundle/source-manifest.json")
jq -n --arg sha "$source_sha256" '{
    schemaVersion: "1.0.0",
    proposalId: "proposal-1",
    decision: "approved",
    approvedBy: "fixture-reviewer",
    approvedAt: "2026-08-09T10:00:00Z",
    sourceFile: "Sources/Banner.swift",
    sourceSHA256: $sha,
    expectedIdentifier: "promoBanner.old",
    candidateIdentifier: "promoBanner.new",
    verificationProfile: "fixture"
}' > "$temporary_directory/approval.json"

"$repository_root/scripts/apply-healing-proposal.sh" \
    "$bundle" "$temporary_directory/approval.json" "$fixture_repository" >/dev/null
grep -Fq 'promoBanner.old' "$fixture_repository/Sources/Banner.swift"
jq -e '.status == "prepared_for_review" and .sourceMutated == false' \
    "$bundle/healing-application.json" >/dev/null

XC_EASY_ALLOW_FIXTURE_HEALING=true XC_EASY_FIXTURE_VERIFICATION_STATUS=0 \
    "$repository_root/scripts/apply-healing-proposal.sh" \
    "$bundle" "$temporary_directory/approval.json" "$fixture_repository" --apply >/dev/null
grep -Fq 'promoBanner.new' "$fixture_repository/Sources/Banner.swift"
jq -e '.status == "applied_and_verified" and .sourceMutated == true' \
    "$bundle/healing-application.json" >/dev/null

printf 'let banner = find(identifier: "promoBanner.old")\n' > "$fixture_repository/Sources/Banner.swift"
source_sha256=$(shasum -a 256 "$fixture_repository/Sources/Banner.swift" | awk '{print $1}')
jq --arg sha "$source_sha256" '.sourceSHA256 = $sha' \
    "$temporary_directory/approval.json" > "$temporary_directory/rollback-approval.json"
jq --arg sha "$source_sha256" '.sources[0].sha256 = $sha' \
    "$bundle/source-manifest.json" > "$temporary_directory/manifest.json"
mv "$temporary_directory/manifest.json" "$bundle/source-manifest.json"

if XC_EASY_ALLOW_FIXTURE_HEALING=true XC_EASY_FIXTURE_VERIFICATION_STATUS=42 \
    "$repository_root/scripts/apply-healing-proposal.sh" \
    "$bundle" "$temporary_directory/rollback-approval.json" "$fixture_repository" --apply >/dev/null 2>&1; then
    echo "Failed verification must return non-zero" >&2
    exit 1
fi
grep -Fq 'promoBanner.old' "$fixture_repository/Sources/Banner.swift"
jq -e '.status == "verification_failed_rolled_back" and .sourceMutated == false' \
    "$bundle/healing-application.json" >/dev/null

echo "Controlled healing application contract test passed"
