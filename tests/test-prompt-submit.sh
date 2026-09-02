#!/usr/bin/env bash
# tests/test-prompt-submit.sh
#
# Unit tests for hooks/prompt-submit.sh — the UserPromptSubmit mode classifier.
#
# Unlike tests/run-fixtures.sh, this suite needs no `claude` CLI and no LLM
# judge: the classifier is deterministic, so every case is a plain assertion
# on the hook's stdout.
#
# The payload built below must mirror the real UserPromptSubmit input exactly.
# An earlier version of this suite invented a `user_prompt` field, and the hook
# read that same invented field, so all 40 cases passed against a classifier
# that was a silent no-op in production. Captured from a live hook, claude
# 2.1.258:
#
#   {"session_id":"...","transcript_path":"...","cwd":"...","prompt_id":"...",
#    "permission_mode":"default","hook_event_name":"UserPromptSubmit",
#    "prompt":"/probe"}
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
  jq -nc --arg p "$1" '{hook_event_name:"UserPromptSubmit",prompt:$p}' | "$HOOK"
}

# run_without <tool> <prompt> -> hook stdout, run against a minimal PATH holding
# only `bash cat tr jq`, minus <tool>. Everything else — perl included — is
# unreachable, so this proves the classifier needs nothing but bash builtins
# and POSIX base utilities.
run_without() {
  local hide="$1" prompt="$2" bin tool resolved
  bin="$(mktemp -d)" || return 1
  for tool in bash cat tr jq; do
    [[ "$tool" == "$hide" ]] && continue
    resolved="$(command -v "$tool")" || continue
    ln -s "$resolved" "$bin/$tool"
  done
  jq -nc --arg p "$prompt" '{hook_event_name:"UserPromptSubmit",prompt:$p}' \
    | PATH="$bin" "$HOOK"
  rm -rf "$bin"
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

# expect_without <label> <hidden-tool> <expected-substring> <prompt>
expect_without() {
  local label="$1" hide="$2" want="$3" prompt="$4" got
  got="$(run_without "$hide" "$prompt")"
  if [[ "$got" == *"$want"* ]]; then
    printf 'PASS  %s\n' "$label"
    ((pass++))
  else
    printf 'FAIL  %s\n      want substring: %s\n      got           : %s\n' "$label" "$want" "${got:-<empty>}"
    ((fail++))
  fi
}

# expect_empty_without <label> <hidden-tool> <prompt>
expect_empty_without() {
  local label="$1" hide="$2" prompt="$3" got
  got="$(run_without "$hide" "$prompt")"
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
# Only the exact token is a path — a prefix match here would over-correct and
# start coaching real commands.
expect 'command sharing a path prefix' "$SKIP" '/tmpfile'
expect 'command: usr-prefixed'         "$SKIP" '/usrlist show all'

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
expect 'hebrew'    "$SKIP" 'תקן את הבאג הזה'

echo '--- Coach: real prompts ---'
expect 'mistake present'  "$COACH" 'i need help with teh build'
expect 'clean prose'      "$COACH" 'is it ready?'
expect 'long substantive' "$COACH" 'please check whether the migration script handles empty tables'

echo '--- Coach: near-miss cases that must NOT skip ---'
# An absolute path is not a slash command. Multi-segment paths never matched
# (the pattern excludes `/`); single-segment top-level paths did.
expect 'absolute path'        "$COACH" '/Users/dev/app/src/main.ts is broken, please look'
expect 'top-level path: tmp'  "$COACH" '/tmp is full, please clean it'
expect 'top-level path: var'  "$COACH" '/var needs cleaning'
expect 'top-level path: etc'  "$COACH" '/etc is where it lives, right?'
# A toggle marker only counts as the entire message.
expect 'toggle inside prose'  "$COACH" 'the readme says nativish:off disables coaching, is that right?'
# An ack word plus real content is a real prompt.
expect 'ack plus content'     "$COACH" 'no, the build is still broken'
# Mostly-Latin with an embedded foreign word stays coachable.
expect 'mixed mostly latin'   "$COACH" 'fix bug в auth.ts please'
# Accented Latin is still Latin — a majority test must not read it as another script.
expect 'accented latin'       "$COACH" 'Können wir das ändern?'
expect 'single accent'        "$COACH" 'café is broken please look'
# Emoji are not a script.
expect 'emoji tail'           "$COACH" 'please fix this 🙏🙏🙏'

# The non-Latin check must be pure bash: no perl, no forks. These are the ten
# cases verified on bash 3.2.57 in issue #3 — kept as a regression guard,
# because the first attempt at this counter failed silently.
echo '--- Non-Latin check works without perl ---'
expect_without 'cyrillic, no perl'     perl "$SKIP"  'привіт, як справи з білдом?'
expect_without 'han, no perl'          perl "$SKIP"  '修复这个错误'
expect_without 'greek, no perl'        perl "$SKIP"  'δοκιμή του κώδικα'
expect_without 'hebrew, no perl'       perl "$SKIP"  'תקן את הבאג הזה'
expect_without 'mixed latin, no perl'  perl "$COACH" 'fix bug в auth.ts please'
expect_without 'ascii, no perl'        perl "$COACH" 'i need help with teh build'
expect_without 'emoji, no perl'        perl "$COACH" 'please fix this 🙏🙏🙏'
expect_without 'accented, no perl'     perl "$COACH" 'Können wir das ändern?'
expect_without 'single accent, no perl' perl "$COACH" 'café is broken please look'
expect_without 'clean short, no perl'  perl "$COACH" 'is it ready?'

echo '--- Fail-open behavior ---'
expect_empty 'empty prompt'   ''
expect_empty 'whitespace only' '   '
# jq is the one external requirement: without it the hook is a silent no-op.
expect_empty_without 'no jq is a silent no-op' jq 'i need help with teh build'

echo
printf 'passed: %d   failed: %d\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
