#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <article_id> <dest_dir>" >&2
  echo "  e.g. $0 24237376 data/raw/eagle-i" >&2
  exit 2
}

[[ $# -eq 2 ]] || usage
ARTICLE_ID="$1"
DEST_DIR="$2"

BASE="https://api.figshare.com/v2/articles/${ARTICLE_ID}"
ART_URL="${BASE}"
FILES_URL="${BASE}/files?page_size=100"

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

md5_of() {
  if command -v md5sum >/dev/null; then md5sum "$1" | awk '{print $1}'
  else md5 -q "$1"; fi          # macOS/BSD
}

mkdir -p "$DEST_DIR"

# 1. Gate: article-level modified_date (string-equality, not a date compare)
modified=$(curl -fsSL "$ART_URL" | jq -r '.modified_date')
stamp="$DEST_DIR/.modified_date"
if [[ -f "$stamp" && "$(cat "$stamp")" == "$modified" ]]; then
  echo "Article $ARTICLE_ID unchanged ($modified); nothing to do."
  exit 0
fi

# 2. Manifest: dedicated files endpoint, paginated up to 100
files=$(curl -fsSL "$FILES_URL")

count=$(printf '%s' "$files" | jq 'length')
echo "Manifest lists $count files (modified_date: $modified)"

# 3. Download only files whose md5 differs
while IFS=$'\t' read -r name md5 url; do
  target="$DEST_DIR/$name"

  if [[ -f "$target" && -n "$md5" && "$(md5_of "$target")" == "$md5" ]]; then
    echo "unchanged: $name"
    continue
  fi
  [[ -f "$target" ]] && echo "changed:   $name" || echo "new:       $name"

  curl -fSL -o "$target" "$url"

  if [[ -n "$md5" && "$(md5_of "$target")" != "$md5" ]]; then
    echo "MD5 MISMATCH for $name" >&2
    exit 1
  fi
done < <(printf '%s' "$files" | jq -r '.[] | [.name, .computed_md5, .download_url] | @tsv')

# 4. Record state for next run's gate
printf '%s' "$modified" > "$stamp"
echo "Done."
