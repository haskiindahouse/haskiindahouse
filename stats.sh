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
