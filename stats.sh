#!/bin/bash
# the wall + the hunt headline, refreshed daily. no widgets.
set -euo pipefail

# the wall: one badge per PUBLIC project i filed issues in (own/work repos excluded).
# is:public is load-bearing: a user-token run must never leak private repo names.
ITEMS=$(gh api "search/issues?q=author:haskiindahouse+is:issue+is:public&per_page=100" --paginate \
  --jq '.items[].repository_url' | sed 's|.*/repos/||' \
  | grep -v -E '^(haskiindahouse|genproof|FitChoice)/' | sort | uniq -c | sort -rn)

TOTAL_BUGS=0
NPROJ=0
WALL=""
while read -r count repo; do
  [ -z "$repo" ] && continue
  TOTAL_BUGS=$((TOTAL_BUGS + count))
  NPROJ=$((NPROJ + 1))
  lang=$(gh api "repos/$repo" --jq '.language // ""' 2>/dev/null || echo "")
  case "$lang" in
    Scala) slug=scala ;; Python) slug=python ;; JavaScript) slug=javascript ;;
    TypeScript) slug=typescript ;; Go) slug=go ;; Java) slug=openjdk ;;
    Kotlin) slug=kotlin ;; Rust) slug=rust ;; C) slug=c ;; C++) slug=cplusplus ;;
    Haskell) slug=haskell ;; Ruby) slug=ruby ;; Groovy) slug=apachegroovy ;;
    Shell) slug=gnubash ;; HTML) slug=html5 ;; *) slug="" ;;
  esac
  name=$(basename "$repo" | tr '[:upper:]' '[:lower:]' | sed 's/-/--/g; s/_/__/g')
  url="https://github.com/$repo/issues?q=author%3Ahaskiindahouse"
  badge="https://img.shields.io/badge/${name}-${count}-555?style=flat-square&labelColor=24292e"
  if [ -n "$slug" ]; then badge="$badge&logo=$slug&logoColor=white"; fi
  WALL="$WALL<a href=\"$url\"><img src=\"$badge\" alt=\"$repo\"></a> "
done <<< "$ITEMS"

HUNT="$TOTAL_BUGS bugs filed across $NPROJ open-source projects"
perl -0pi -e "s|<!--hunt-->.*?<!--/hunt-->|<!--hunt-->$HUNT<!--/hunt-->|s" README.md
perl -0pi -e "s|<!--wall-->.*?<!--/wall-->|<!--wall-->$WALL<!--/wall-->|s" README.md
echo "hunt: $HUNT"
