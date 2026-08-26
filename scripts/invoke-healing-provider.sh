#!/bin/sh
set -eu

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <source-bundle> <provider-config.json> <provider-response.json> [forbidden-canary]" >&2
    exit 64
fi

source_bundle=$(cd "$1" && pwd -P)
provider_config=$2
output=$3
forbidden_canary=${4:-}
manifest="$source_bundle/source-manifest.json"
proposals="$source_bundle/healing-proposals.json"

[ -f "$manifest" ] || { echo "Source manifest not found" >&2; exit 66; }
[ -f "$proposals" ] || { echo "Healing proposals not found" >&2; exit 66; }
[ -f "$provider_config" ] || { echo "Provider configuration not found" >&2; exit 66; }
[ ! -e "$output" ] || { echo "Provider response destination already exists: $output" >&2; exit 73; }

jq -e '
    .schemaVersion == "1.0.0" and
    (.providerId | type == "string" and test("^[A-Za-z0-9_.:-]+$")) and
    (.command | type == "array" and length > 0 and length <= 20) and
    all(.command[]; type == "string" and length > 0 and length <= 4096 and (contains("\n") | not)) and
    (.timeoutSeconds | type == "number" and . >= 1 and . <= 600)
' "$provider_config" >/dev/null
jq -e '
    .schemaVersion == "1.0.0" and
    .policy.assertionsMayChange == false and
    .policy.humanApprovalRequired == true and
    (.proposalId | type == "string" and length > 0)
' "$manifest" >/dev/null

provider_id=$(jq -r '.providerId' "$provider_config")
timeout_seconds=$(jq -r '.timeoutSeconds | floor' "$provider_config")
proposal_id=$(jq -r '.proposalId' "$manifest")
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/xceasy-provider.XXXXXX")
cleanup() { rm -rf "$temporary_directory"; }
trap cleanup EXIT
command_file="$temporary_directory/command.txt"
request="$temporary_directory/provider-request.json"
response="$temporary_directory/provider-response.json"
jq -r '.command[]' "$provider_config" > "$command_file"

jq -n \
    --arg provider_id "$provider_id" \
    --arg proposal_id "$proposal_id" \
    --slurpfile manifest "$manifest" \
    --slurpfile proposals "$proposals" '
    {
        schemaVersion: "1.0.0",
        providerId: $provider_id,
        proposalId: $proposal_id,
        sourceManifest: $manifest[0],
        healingProposals: $proposals[0],
        contract: {
            responseIsSuggestionOnly: true,
            candidateMustComeFromEvidence: true,
            assertionsMayChange: false,
            humanApprovalRequired: true
        }
    }
' > "$request"

set --
while IFS= read -r argument; do
    set -- "$@" "$argument"
done < "$command_file"

if perl -e '
    my $timeout = shift @ARGV;
    alarm($timeout);
    exec @ARGV;
    exit 127;
' "$timeout_seconds" "$@" \
    --request "$request" \
    --source-bundle "$source_bundle" \
    --response "$response"; then
    :
else
    status=$?
    echo "Healing provider failed or timed out: $provider_id (exit $status)" >&2
    exit "$status"
fi

[ -f "$response" ] || { echo "Healing provider did not create a response" >&2; exit 65; }
if [ -n "$forbidden_canary" ] && grep -Fq -- "$forbidden_canary" "$response"; then
    echo "Forbidden canary found in healing provider response" >&2
    exit 65
fi

jq -e \
    --arg provider_id "$provider_id" \
    --arg proposal_id "$proposal_id" '
    .schemaVersion == "1.0.0" and
    .providerId == $provider_id and
    .proposalId == $proposal_id and
    .decision == "suggest" and
    (.candidateIdentifier | type == "string" and test("^[A-Za-z0-9_.:-]+$")) and
    (.evidenceCandidateIndex | type == "number" and . >= 0 and floor == .) and
    (.reasonCodes | type == "array" and length > 0 and length <= 20) and
    all(.reasonCodes[]; type == "string" and test("^[a-z0-9_.-]+$") and length <= 128) and
    .assertionsChanged == false and
    .requiresHumanApproval == true
' "$response" >/dev/null

candidate_identifier=$(jq -r '.candidateIdentifier' "$response")
candidate_index=$(jq -r '.evidenceCandidateIndex' "$response")
jq -e \
    --arg proposal_id "$proposal_id" \
    --arg candidate "$candidate_identifier" \
    --argjson candidate_index "$candidate_index" '
    any(.[];
        .proposalId == $proposal_id and
        .disposition == "suggested" and
        .requiresHumanApproval == true and
        any(.rankedCandidates[];
            .evidenceCandidateIndex == $candidate_index and
            .identifier == $candidate
        )
    )
' "$proposals" >/dev/null

mkdir -p "$(dirname "$output")"
mv "$response" "$output"
echo "Validated suggestion from healing provider $provider_id: $output"
