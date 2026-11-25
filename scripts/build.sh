#!/bin/sh
# Assemble one site into dist/<site> and refuse to build if a permanent URL is missing.
# Usage: sh scripts/build.sh company|tya
# A failed build means the host keeps serving the previous version, so a broken
# redesign can never take a store-submitted URL offline.
set -eu

SITE="${1:?usage: sh scripts/build.sh company|tya}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist/$SITE"

[ -d "$ROOT/$SITE" ] || { echo "Unknown site: $SITE" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT"
cp -R "$ROOT/$SITE/." "$OUT/"
mkdir -p "$OUT/assets"
cp -R "$ROOT/shared/." "$OUT/assets/"

fail=0
while read -r site path; do
  case "$site" in ''|'#'*) continue ;; esac
  [ "$site" = "$SITE" ] || continue
  file="$OUT$path"
  if [ ! -s "$file" ]; then
    echo "PERMANENT URL MISSING: $SITE $path" >&2; fail=1
  elif ! grep -qi '<title>[^<][^<]*</title>' "$file"; then
    echo "PERMANENT URL HAS NO <title>: $SITE $path" >&2; fail=1
  fi
done < "$ROOT/scripts/permanent-urls.txt"

[ "$fail" -eq 0 ] || { echo "Build refused — restore the missing permanent URL(s)." >&2; exit 1; }
echo "Built $SITE → dist/$SITE (permanent URLs OK)"
