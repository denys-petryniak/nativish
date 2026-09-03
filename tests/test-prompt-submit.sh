#!/usr/bin/env bash
# Unit tests for hooks/prompt-submit.sh.
#
# The hook is one printf of one constant string: it reads nothing and decides
# nothing, so there is no classification to test. What can actually break is
# drift — the directive naming a mode the rulebook no longer defines. That is
# the one check a green suite could not fake by sharing a wrong assumption
# with the hook, because it reads the other file to check.
#
# Exit: 0 all pass, 1 any fail, 2 setup error.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$REPO/hooks/prompt-submit.sh"
SKILL="$REPO/skills/english-coaching/SKILL.md"

[[ -x $HOOK ]] || { echo "ERROR: $HOOK missing or not executable" >&2; exit 2; }
[[ -r $SKILL ]] || { echo "ERROR: $SKILL missing" >&2; exit 2; }

fail=0
check() { # check <label> <problem-or-empty>
  if [[ -z $2 ]]; then printf 'PASS  %s\n' "$1"
  else printf 'FAIL  %s\n      %s\n' "$1" "$2"; fail=1; fi
}

# Closed stdin, so a hook that ever starts reading input hangs the suite here.
out=$("$HOOK" </dev/null 2>&1) || out="<exited $?>"
lines=$(printf '%s' "$out" | grep -c '')

# One line only: more would read as multi-part context rather than a directive.
problem=''
[[ $out == *'[nativish] Hook directive'* ]] || problem="no directive in: $out"
[[ $lines -eq 1 ]] || problem="got $lines lines, want 1"
check 'emits exactly one line of directive' "$problem"

# Every mode the directive names must still be defined in the rulebook.
undefined=$(printf '%s' "$out" | grep -oE 'Mode [0-9]+' | sort -u |
  while read -r mode; do grep -qi "$mode" "$SKILL" || printf '%s ' "$mode"; done)
check 'directive names only modes the rulebook defines' "${undefined:+not in SKILL.md: $undefined}"

[[ $fail -eq 0 ]]
