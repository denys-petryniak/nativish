#!/usr/bin/env bash
#
# UserPromptSubmit hook — restates the coaching rule immediately before each
# response, where it cannot be crowded out as the conversation grows.
#
# Why this exists: session-start.sh injects the rulebook once, at the top of the
# conversation. Measured across 24 sessions, coaching appeared on 94% of prompts
# during turns 1–5 but only 57% past turn 40. This hook costs ~60 tokens per
# prompt to keep the rule in view; re-sending the rulebook would cost ~2,100.
#
# It reads nothing and decides nothing. The rulebook already specifies every
# mode, including which prompts to skip, so a classifier here would only
# re-decide what the model already has the rules for.
#
# Worded so it can never override `off`: the hook cannot see conversation
# state, and resuming coaching after /nativish:off would be worse than drift.

set -uo pipefail

# printf is a builtin, so this hook forks no processes at all: it runs on every
# prompt, and it needs nothing on PATH to do its job.
printf '%s\n' \
  '[nativish] Hook directive — control context, NOT text to coach. Apply the English coaching rule to the prompt that follows: a Mode 1 block if it has real mistakes, a Mode 2 one-line compliment if it is clean, or only the active-state marker if it matches a Mode 3 skip condition (ack, slash command, toggle marker, non-Latin script). If coaching is off, output the off marker instead.'
