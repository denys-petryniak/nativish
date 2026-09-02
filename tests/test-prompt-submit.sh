#!/usr/bin/env bash
# Unit tests for hooks/prompt-submit.sh.
#
# The hook reads nothing and decides nothing, so there is no classification to
# test and no point varying the payload. These four are the ways it could fail
# on a prompt the user actually submitted.
#
# Exit: 0 all pass, 1 any fail, 2 setup error.

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/hooks/prompt-submit.sh"
PAYLOAD='{"hook_event_name":"UserPromptSubmit","prompt":"i need help with teh build"}'
DIRECTIVE='[nativish] Hook directive'

if [[ ! -x $HOOK ]]; then
  echo "ERROR: $HOOK missing or not executable" >&2
  exit 2
fi

pass=0
fail=0

check() {
  local label=$1 status=$2 out=$3
  if [[ $status -eq 0 && $out == *"$DIRECTIVE"* ]]; then
    printf 'PASS  %s\n' "$label"
    ((pass++))
  else
    printf 'FAIL  %s\n      exit: %s (want 0)\n      out : %s\n' "$label" "$status" "${out:-<empty>}"
    ((fail++))
  fi
}

out=$(printf '%s' "$PAYLOAD" | "$HOOK" 2>&1)
check 'emits the directive' $? "$out"

# Must not hang waiting for input.
out=$("$HOOK" </dev/null 2>&1)
check 'stdin closed' $? "$out"

# The README claims no dependencies. Absolute interpreter, so this tests the
# hook body rather than whether env can still resolve bash.
out=$(printf '%s' "$PAYLOAD" | PATH='' "$(command -v bash)" "$HOOK" 2>&1)
check 'no PATH, no dependencies' $? "$out"

# One line, so it cannot be mistaken for multi-part context.
lines=$(printf '%s' "$PAYLOAD" | "$HOOK" | wc -l | tr -d ' ')
if [[ $lines -eq 1 ]]; then
  printf 'PASS  %s\n' 'exactly one line of output'
  ((pass++))
else
  printf 'FAIL  %s\n      got %s lines, want 1\n' 'exactly one line of output' "$lines"
  ((fail++))
fi

echo
printf 'passed: %d   failed: %d\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
