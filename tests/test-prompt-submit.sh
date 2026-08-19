#!/usr/bin/env bash
# tests/test-prompt-submit.sh
#
# Unit tests for hooks/prompt-submit.sh — the UserPromptSubmit mode classifier.
#
# Unlike tests/run-fixtures.sh, this suite needs no `claude` CLI and no LLM
# judge: the classifier is deterministic, so every case is a plain assertion
# on the hook's stdout.
#
# Usage:
#   tests/test-prompt-submit.sh
#
# Exit code: 0 if all cases pass, 1 if any fail, 2 on setup errors.

set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/hooks/prompt-submit.sh"

if [[ ! -x "$HOOK" ]]; then
  echo "ERROR: $HOOK missing or not executable" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq not found on PATH" >&2
  exit 2
fi

pass=0
fail=0

# run <prompt> -> hook stdout
run() {
  jq -nc --arg p "$1" '{hook_event_name:"UserPromptSubmit",user_prompt:$p}' | "$HOOK"
}

# expect <label> <expected-substring> <prompt>
expect() {
  local label="$1" want="$2" prompt="$3" got
  got="$(run "$prompt")"
  if [[ "$got" == *"$want"* ]]; then
    printf 'PASS  %s\n' "$label"
    ((pass++))
  else
    printf 'FAIL  %s\n      want substring: %s\n      got           : %s\n' "$label" "$want" "${got:-<empty>}"
    ((fail++))
  fi
}

# expect_empty <label> <prompt>
expect_empty() {
  local label="$1" prompt="$2" got
  got="$(run "$prompt")"
  if [[ -z "${got//[[:space:]]/}" ]]; then
    printf 'PASS  %s\n' "$label"
    ((pass++))
  else
    printf 'FAIL  %s\n      want no output, got: %s\n' "$label" "$got"
    ((fail++))
  fi
}

# Sentinels must be mutually exclusive: the coach directive also contains the
# words "Mode 3", so a looser skip sentinel would match either branch.
SKIP='matches a Mode 3 skip condition'
COACH='not a Mode 3 skip'

echo '--- Mode 3: slash commands ---'
expect 'bare slash command'        "$SKIP" '/commit'
expect 'slash command with args'   "$SKIP" '/pr-create add the thing'
expect 'slash command, leading ws' "$SKIP" '   /test'

echo '--- Mode 3: short acknowledgments ---'
expect 'ack: ok'          "$SKIP" 'ok'
expect 'ack: thanks'      "$SKIP" 'thanks'
expect 'ack: uppercase'   "$SKIP" 'OK'
expect 'ack: punctuated'  "$SKIP" 'yes!'
expect 'ack: two words'   "$SKIP" 'got it'
expect 'ack: sounds good' "$SKIP" 'sounds good'

echo '--- Mode 3: toggle markers ---'
expect 'toggle colon off'   "$SKIP" 'nativish:off'
expect 'toggle space on'    "$SKIP" 'nativish on'
expect 'toggle strict'      "$SKIP" 'nativish:strict'
expect 'toggle mixed case'  "$SKIP" 'Nativish:Off'

echo '--- Mode 3: non-Latin script ---'
expect 'cyrillic'  "$SKIP" 'привіт, як справи з білдом?'
expect 'han'       "$SKIP" '修复这个错误'
expect 'greek'     "$SKIP" 'δοκιμή του κώδικα'

echo '--- Coach: real prompts ---'
expect 'mistake present'  "$COACH" 'i need help with teh build'
expect 'clean prose'      "$COACH" 'is it ready?'
expect 'long substantive' "$COACH" 'please check whether the migration script handles empty tables'

echo '--- Coach: near-miss cases that must NOT skip ---'
# An absolute path is not a slash command.
expect 'absolute path'        "$COACH" '/Users/dev/app/src/main.ts is broken, please look'
# A toggle marker only counts as the entire message.
expect 'toggle inside prose'  "$COACH" 'the readme says nativish:off disables coaching, is that right?'
# An ack word plus real content is a real prompt.
expect 'ack plus content'     "$COACH" 'no, the build is still broken'
# Mostly-Latin with an embedded foreign word stays coachable.
expect 'mixed mostly latin'   "$COACH" 'fix bug в auth.ts please'

echo '--- Fail-open behavior ---'
expect_empty 'empty prompt'   ''
expect_empty 'whitespace only' '   '

echo
printf 'passed: %d   failed: %d\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
