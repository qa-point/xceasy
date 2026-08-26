#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
temporary_directory=$(mktemp -d)
trap 'rm -rf "$temporary_directory"' EXIT
bundle="$temporary_directory/source-bundle"
mkdir -p "$bundle/sources"

jq -n '{
    schemaVersion: "1.0.0",
    proposalId: "proposal-1",
    policy: {maximumBytes: 1048576, assertionsMayChange: false, humanApprovalRequired: true},
    totalBytes: 0,
    sources: []
}' > "$bundle/source-manifest.json"
jq -n '[{
    schemaVersion: "1.0.0",
    proposalId: "proposal-1",
    disposition: "suggested",
    reasonCode: "healing.candidate_ready_for_review",
    requiresHumanApproval: true,
    rankedCandidates: [{
        evidenceCandidateIndex: 0,
        identifier: "promoBanner.new",
        elementType: "button",
        confidence: 0.9,
        reasonCodes: ["healing.evidence_candidate"]
    }],
    verification: {required: true, originalFailureMustRemainLinked: true}
}]' > "$bundle/healing-proposals.json"
jq -n \
    --arg command "$repository_root/scripts/tests/fixtures/fake-healing-provider.sh" '{
    schemaVersion: "1.0.0",
    providerId: "fixture-provider",
    command: [$command],
    timeoutSeconds: 10
}' > "$temporary_directory/provider.json"

"$repository_root/scripts/invoke-healing-provider.sh" \
    "$bundle" "$temporary_directory/provider.json" "$temporary_directory/response.json" >/dev/null
jq -e '
    .providerId == "fixture-provider" and
    .candidateIdentifier == "promoBanner.new" and
    .assertionsChanged == false and
    .requiresHumanApproval == true
' "$temporary_directory/response.json" >/dev/null

if XC_EASY_FAKE_PROVIDER_MODE=unlisted \
    "$repository_root/scripts/invoke-healing-provider.sh" \
    "$bundle" "$temporary_directory/provider.json" "$temporary_directory/unlisted.json" >/dev/null 2>&1; then
    echo "Provider adapter accepted a candidate that was absent from evidence" >&2
    exit 1
fi

if XC_EASY_FAKE_PROVIDER_MODE=assertion-change \
    "$repository_root/scripts/invoke-healing-provider.sh" \
    "$bundle" "$temporary_directory/provider.json" "$temporary_directory/assertion-change.json" >/dev/null 2>&1; then
    echo "Provider adapter accepted an assertion-changing response" >&2
    exit 1
fi

echo "Provider-neutral healing adapter contract tests passed"
