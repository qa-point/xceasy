#!/bin/sh
set -eu

if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
    echo "Usage: $0 <handoff-directory> <source-map.json> <repository-root> <output-directory> [forbidden-canary]" >&2
    exit 64
fi

handoff_directory=$(cd "$1" && pwd)
source_map=$2
repository_root=$(cd "$3" && pwd -P)
output=$4
forbidden_canary=${5:-}
script_directory=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

"$script_directory/validate-ai-handoff.sh" "$handoff_directory" "$forbidden_canary" >/dev/null
jq -e '
    .schemaVersion == "1.0.0" and
    (.proposalId | type == "string" and length > 0) and
    (.sourceFiles | type == "array" and length > 0 and length <= 20) and
    all(.sourceFiles[];
        (.path | type == "string" and endswith(".swift")) and
        (.selectorIdentifier | type == "string" and length > 0)
    )
' "$source_map" >/dev/null

proposal_id=$(jq -r '.proposalId' "$source_map")
jq -e --arg proposal_id "$proposal_id" 'any(.[]; .proposalId == $proposal_id)' \
    "$handoff_directory/healing-proposals.json" >/dev/null

if [ -e "$output" ]; then
    echo "Source-bundle destination already exists: $output" >&2
    exit 73
fi

temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/xceasy-source-bundle.XXXXXX")
cleanup() {
    status=$?
    if [ "$status" -eq 0 ]; then
        rm -rf "$temporary_directory"
    else
        echo "Retained failed source-bundle workspace: $temporary_directory" >&2
    fi
}
trap cleanup EXIT
bundle="$temporary_directory/bundle"
mkdir -p "$bundle/sources"
manifest_entries="$temporary_directory/manifest.jsonl"
source_entries="$temporary_directory/source-entries.jsonl"
: > "$manifest_entries"
total_bytes=0

jq -c '.sourceFiles[]' "$source_map" > "$source_entries"
while IFS= read -r entry; do
    relative_path=$(printf '%s' "$entry" | jq -r '.path')
    case "$relative_path" in
        /*|../*|*/../*|*/..|..|*//*|*\\*)
            echo "Unsafe source path: $relative_path" >&2
            exit 65
            ;;
    esac
    source="$repository_root/$relative_path"
    [ -f "$source" ] || { echo "Mapped source file not found: $relative_path" >&2; exit 66; }
    [ ! -L "$source" ] || { echo "Symlinked source files are not accepted: $relative_path" >&2; exit 65; }
    resolved_directory=$(cd "$(dirname "$source")" && pwd -P)
    case "$resolved_directory/$(basename "$source")" in
        "$repository_root"/*) ;;
        *) echo "Source escapes repository root: $relative_path" >&2; exit 65 ;;
    esac
    if grep -Eiq '(api[_-]?key|authorization|password|secret|access[_-]?token)[[:space:]]*[:=][[:space:]]*"[^"[:space:]]{6,}"' "$source"; then
        echo "Possible embedded secret blocks AI source export: $relative_path" >&2
        exit 65
    fi
    if [ -n "$forbidden_canary" ] && grep -Fq -- "$forbidden_canary" "$source"; then
        echo "Forbidden canary blocks AI source export: $relative_path" >&2
        exit 65
    fi
    bytes=$(wc -c < "$source" | tr -d ' ')
    total_bytes=$((total_bytes + bytes))
    if [ "$total_bytes" -gt 1048576 ]; then
        echo "AI source bundle exceeds the 1 MiB limit" >&2
        exit 65
    fi
    destination="$bundle/sources/$relative_path"
    mkdir -p "$(dirname "$destination")"
    cp "$source" "$destination"
    sha256=$(shasum -a 256 "$source" | awk '{print $1}')
    selector_identifier=$(printf '%s' "$entry" | jq -r '.selectorIdentifier')
    jq -nc \
        --arg path "$relative_path" \
        --arg selector_identifier "$selector_identifier" \
        --arg sha256 "$sha256" \
        --argjson bytes "$bytes" \
        '{path: $path, selectorIdentifier: $selector_identifier, bytes: $bytes, sha256: $sha256}' \
        >> "$manifest_entries"
done < "$source_entries"

cp "$handoff_directory/healing-proposals.json" "$bundle/healing-proposals.json"
cp "$handoff_directory/test-generation-request.json" "$bundle/test-generation-request.json"
cp "$handoff_directory/reproduction.md" "$bundle/reproduction.md"
jq -n \
    --arg proposal_id "$proposal_id" \
    --argjson total_bytes "$total_bytes" \
    --slurpfile sources "$manifest_entries" '
    {
        schemaVersion: "1.0.0",
        proposalId: $proposal_id,
        policy: {
            maximumBytes: 1048576,
            assertionsMayChange: false,
            humanApprovalRequired: true
        },
        totalBytes: $total_bytes,
        sources: $sources
    }' > "$bundle/source-manifest.json"

mkdir -p "$(dirname "$output")"
mv "$bundle" "$output"
echo "AI healing source bundle written to $output"
