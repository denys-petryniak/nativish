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
# Dependencies: `jq`, for the one line that reads `user_prompt` off stdin.
# Everything else is a bash builtin, targeting bash 3.2 — the version macOS
# still ships.
#
# Fails open by design — on any missing dependency, malformed payload, or
# unexpected error, it prints nothing and exits 0. A broken coach must never
# swallow the user's prompt.

set -uo pipefail

payload="$(cat 2>/dev/null)" || exit 0
[[ -n "$payload" ]] || exit 0

command -v jq >/dev/null 2>&1 || exit 0
# The field is `prompt`. An earlier version read `.user_prompt`, which does not
# exist, so the hook exited 0 with no output on every prompt ever submitted.
prompt="$(printf '%s' "$payload" | jq -r '.prompt // empty' 2>/dev/null)" || exit 0

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
# UserPromptSubmit fires *before* expansion, so the hook does see the literal
# `/commit` the user typed. (Expansion has its own event, UserPromptExpansion.)
#
# Command tokens are lowercase and unbroken, which already excludes multi-
# segment paths: `/` is not in the character class, so `/etc/hosts is full` and
# `/Users/dev/app.ts is broken` fall through to coach.
#
# Single-segment top-level paths are the exception, because `/tmp is full` and
# `/pr-create add the thing` have exactly the same shape — structure alone
# cannot separate them. Hence the denylist below. Denylists are usually the
# wrong tool; this one earns its place because the list is finite and fixed by
# decades of filesystem convention, and a miss costs one uncoached prompt
# rather than a broken one. `Users`, `Applications`, `Library`, `System` and
# `Volumes` need no entry — the leading-lowercase rule already excludes them.
if [[ "$first_line" =~ ^/([a-z][a-z0-9:_-]*)([[:space:]].*)?$ ]]; then
  case "${BASH_REMATCH[1]}" in
    tmp | etc | usr | var | opt | bin | sbin | dev | home | lib | mnt | srv | proc | sys | root) ;;
    *) skip 'slash command' ;;
  esac
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
# Bash builtins only: no forks, no external tools. A majority test — skip when
# non-ASCII characters outnumber Latin letters — so a mostly-English prompt with
# an embedded foreign word, an accent, or a trailing emoji stays coachable.
#
# This does not know *which* script it saw, so `Können`, `café` and emoji all
# count as non-ASCII. The majority test absorbs that; only a message that is
# overwhelmingly accented would misfire, which is rare and low-impact.
#
# `[![:ascii:]]` is the form that works on bash 3.2. The first attempt used
# `[!$'\x01'-$'\x7f']` and silently reported 26 non-ASCII characters in
# pure-ASCII text, because 3.2 does not read $'...' as a range inside a pattern
# bracket. Correct in either locale: under a UTF-8 one the counts are
# characters, under C they are bytes, and the verdict is the same.
latin_only="${trimmed//[!a-zA-Z]/}"
ascii_only="${trimmed//[![:ascii:]]/}"
if (( ${#trimmed} - ${#ascii_only} > ${#latin_only} )); then
  skip 'non-Latin script'
fi

coach
