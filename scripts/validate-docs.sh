#!/bin/sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$repository_root"

require_file() {
    [ -f "$1" ] || {
        echo "Missing documentation counterpart: $1" >&2
        exit 1
    }
}

require_file README.md
require_file README_EN.md
require_file README_RU.md

for english_file in docs/en/*_EN.md docs/en/spec/*_EN.md docs/en/guide/*_EN.md; do
    relative_path=${english_file#docs/en/}
    russian_path=$(printf '%s\n' "$relative_path" | sed 's/_EN\.md$/_RU.md/')
    require_file "docs/ru/$russian_path"
done

for russian_file in docs/ru/*_RU.md docs/ru/spec/*_RU.md docs/ru/guide/*_RU.md; do
    relative_path=${russian_file#docs/ru/}
    english_path=$(printf '%s\n' "$relative_path" | sed 's/_RU\.md$/_EN.md/')
    require_file "docs/en/$english_path"
done

for english_file in docs/en/adr/*.md docs/en/migration/*.md; do
    [ -e "$english_file" ] || continue
    relative_path=${english_file#docs/en/}
    require_file "docs/ru/$relative_path"
done

for russian_file in docs/ru/adr/*.md docs/ru/migration/*.md; do
    [ -e "$russian_file" ] || continue
    relative_path=${russian_file#docs/ru/}
    require_file "docs/en/$relative_path"
done

link_list=$(mktemp "${TMPDIR:-/tmp}/xceasy-doc-links.XXXXXX")
trap 'rm -f "$link_list"' EXIT HUP INT TERM

find docs -type f -name '*.md' -exec perl -ne \
    'while (/\[[^\]]*\]\(([^)]+)\)/g) { print "$ARGV\t$1\n" }' {} + >"$link_list"

while IFS="$(printf '\t')" read -r source_file raw_target; do
    case "$raw_target" in
        http://*|https://*|mailto:*|\#*) continue ;;
    esac

    target=${raw_target#<}
    target=${target%>}
    target=${target%%#*}
    [ -n "$target" ] || continue

    source_directory=$(dirname "$source_file")
    if ! (cd "$source_directory" && [ -e "$target" ]); then
        echo "Broken documentation link: $source_file -> $raw_target" >&2
        exit 1
    fi
done <"$link_list"

echo "Documentation validation passed: RU/EN counterparts and local links are intact."
