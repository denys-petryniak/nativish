#!/usr/bin/env bash
# tests/test-prompt-submit.sh
#
# Unit tests for hooks/prompt-submit.sh — the UserPromptSubmit reminder.
#
# The hook reads nothing and decides nothing, so there is no classification to
# test and no point varying the payload: every input takes the same code path.
# What matters is that it runs on every prompt the user submits, so these four
# cases cover the ways that could go wrong.
#
# Usage:  tests/test-prompt-submit.sh
# Exit:   0 if all cases pass, 1 if any fail, 2 on setup errors.

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

# check <label> <exit-status> <output>
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

# Emits the directive and succeeds.
out=$(printf '%s' "$PAYLOAD" | "$HOOK" 2>&1)
check 'emits the directive' $? "$out"

# Must not hang or error when there is nothing to read.
out=$("$HOOK" </dev/null 2>&1)
check 'stdin closed' $? "$out"

# printf is a builtin, so an empty PATH must still work — this is the claim the
# README makes about having no dependencies. Invoked through an absolute
# interpreter, so the test exercises the hook body rather than whether `env`
# can still resolve bash.
out=$(printf '%s' "$PAYLOAD" | PATH='' "$(command -v bash)" "$HOOK" 2>&1)
check 'no PATH, no dependencies' $? "$out"

# One line only, so it cannot be mistaken for multi-part context.
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
