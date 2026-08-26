#!/bin/sh
set -eu

request=
response=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --request) request=$2; shift 2 ;;
        --source-bundle) shift 2 ;;
        --response) response=$2; shift 2 ;;
        *) echo "Unexpected fake-provider argument: $1" >&2; exit 64 ;;
    esac
done

[ -n "$request" ] && [ -n "$response" ] || exit 64
proposal_id=$(jq -r '.proposalId' "$request")
provider_id=$(jq -r '.providerId' "$request")
candidate=$(jq -r '.healingProposals[0].rankedCandidates[0].identifier' "$request")
candidate_index=$(jq -r '.healingProposals[0].rankedCandidates[0].evidenceCandidateIndex' "$request")

case "${XC_EASY_FAKE_PROVIDER_MODE:-valid}" in
    valid) ;;
    unlisted) candidate="not.in.evidence" ;;
    assertion-change) assertions_changed=true ;;
    *) exit 64 ;;
esac

jq -n \
    --arg provider_id "$provider_id" \
    --arg proposal_id "$proposal_id" \
    --arg candidate "$candidate" \
    --argjson candidate_index "$candidate_index" \
    --argjson assertions_changed "${assertions_changed:-false}" '
    {
        schemaVersion: "1.0.0",
        providerId: $provider_id,
        proposalId: $proposal_id,
        decision: "suggest",
        candidateIdentifier: $candidate,
        evidenceCandidateIndex: $candidate_index,
        reasonCodes: ["provider.evidence_ranked_candidate"],
        assertionsChanged: $assertions_changed,
        requiresHumanApproval: true
    }
' > "$response"
