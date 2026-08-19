#!/usr/bin/env bash
#
# UserPromptSubmit hook — classifies the incoming prompt's coaching mode and
# injects a one-line directive into the conversation context.
#
# Why this exists: the SessionStart hook injects the rulebook once, at the top
# of the conversation. The further the conversation gets from that injection,
# the more often the coaching block is dropped. This hook restates the mode
# decision immediately before each response, where it cannot be crowded out.
#
# Division of labour: every Mode 3 skip condition is mechanically decidable, so
# it is decided here. The Mode 1 (mistakes) vs Mode 2 (clean) split needs a
# reader, so it stays with the model.
#
# Fails open by design — on any missing dependency, malformed payload, or
# unexpected error, it prints nothing and exits 0. A broken coach must never
# swallow the user's prompt.

set -uo pipefail

payload="$(cat 2>/dev/null)" || exit 0
[[ -n "$payload" ]] || exit 0

command -v jq >/dev/null 2>&1 || exit 0
prompt="$(printf '%s' "$payload" | jq -r '.user_prompt // empty' 2>/dev/null)" || exit 0

# Trim leading and trailing whitespace.
trimmed="${prompt#"${prompt%%[![:space:]]*}"}"
trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
[[ -n "$trimmed" ]] || exit 0

PREFIX='[nativish] Hook directive — control context, NOT text to coach.'

skip() {
  printf '%s This prompt matches a Mode 3 skip condition (%s). Output only the active-state marker on its own line, with no dividers, then answer the prompt.\n' \
    "$PREFIX" "$1"
  exit 0
}

coach() {
  printf '%s This prompt is not a Mode 3 skip: coach it before answering — Mode 1 block if it has real mistakes, Mode 2 one-line compliment if it is clean. If coaching is off, output the off marker instead.\n' \
    "$PREFIX"
  exit 0
}

first_line="${trimmed%%$'\n'*}"
lower_trimmed="$(printf '%s' "$trimmed" | tr '[:upper:]' '[:lower:]')"

# --- Mode 3: slash command ---------------------------------------------------
# Command tokens are lowercase and unbroken; this deliberately excludes pasted
# absolute paths such as /Users/dev/app.ts or /etc/hosts.
if [[ "$first_line" =~ ^/[a-z][a-z0-9:_-]*([[:space:]].*)?$ ]]; then
  skip 'slash command'
fi

# --- Mode 3: toggle marker ---------------------------------------------------
# Only when the marker is the entire message — a marker quoted inside prose or
# pasted docs must not flip state.
toggle="$(printf '%s' "$lower_trimmed" | tr -s '[:space:]' ' ')"
if [[ "$toggle" =~ ^nativish[:\ ](on|off|strict)$ ]]; then
  skip 'toggle marker'
fi

# --- Mode 3: short acknowledgment -------------------------------------------
# List kept identical to the one in skills/english-coaching/SKILL.md.
if [[ "$trimmed" != *$'\n'* ]]; then
  ack="$(printf '%s' "$lower_trimmed" | tr -cd 'a-z ' | tr -s ' ')"
  ack="${ack# }"
  ack="${ack% }"
  case "$ack" in
    yes | no | ok | sure | thanks | thx | nope | cool | great | nice | done | 'got it' | 'sounds good')
      skip 'short acknowledgment'
      ;;
  esac
fi

# --- Mode 3: non-Latin script -----------------------------------------------
# Scripts enumerated to match SKILL.md. Skips only when non-Latin letters
# outnumber Latin ones, so an English prompt with an embedded foreign word
# stays coachable. Without perl, this check is skipped and the model decides.
if command -v perl >/dev/null 2>&1; then
  counts="$(printf '%s' "$trimmed" | perl -CS -e '
    my $t = do { local $/; <STDIN> };
    my $other = () = $t =~ /[\p{Cyrillic}\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}\p{Arabic}\p{Hebrew}\p{Greek}\p{Devanagari}\p{Thai}]/g;
    my $latin = () = $t =~ /\p{Latin}/g;
    print "$other $latin";
  ' 2>/dev/null)" || counts=''
  if [[ "$counts" =~ ^([0-9]+)\ ([0-9]+)$ ]]; then
    other="${BASH_REMATCH[1]}"
    latin="${BASH_REMATCH[2]}"
    if (( other > latin )); then
      skip 'non-Latin script'
    fi
  fi
fi

coach
