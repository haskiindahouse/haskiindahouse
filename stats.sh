#!/bin/bash
# quiet stats: one line of text, refreshed daily. no widgets.
set -euo pipefail

Q='query { user(login: "haskiindahouse") { contributionsCollection { contributionCalendar { totalContributions weeks { contributionDays { date contributionCount } } } } } }'

TOTAL=$(gh api graphql -f query="$Q" --jq '.data.user.contributionsCollection.contributionCalendar.totalContributions')
COUNTS=$(gh api graphql -f query="$Q" --jq '[.data.user.contributionsCollection.contributionCalendar.weeks[].contributionDays[]] | sort_by(.date) | reverse | map(.contributionCount) | join(" ")')

STREAK=0
FIRST=1
for c in $COUNTS; do
  if [ "$FIRST" = "1" ]; then
    FIRST=0
    # today can still be 0 without breaking the streak
    if [ "$c" = "0" ]; then continue; fi
  fi
  if [ "$c" -gt 0 ]; then STREAK=$((STREAK + 1)); else break; fi
done

LINE="$TOTAL contributions in the last year \xC2\xB7 $STREAK-day streak"
LINE=$(printf "$LINE")

perl -0pi -e "s/<!--stats-->.*?<!--\\/stats-->/<!--stats-->$LINE<!--\\/stats-->/s" README.md
echo "stats: $TOTAL · ${STREAK}d"

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
