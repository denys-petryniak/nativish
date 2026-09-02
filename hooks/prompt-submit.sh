#!/usr/bin/env bash
#
# Restates the coaching rule before each response. session-start.sh injects the
# rulebook once, and it gets dropped more often the further a session runs.
#
# Reads nothing, decides nothing: the rulebook already specifies every mode,
# skips included, so a classifier here would just re-decide what the model
# already has the rules for.
#
# The wording must never override `off` — the hook cannot see conversation
# state, and resuming coaching after /nativish:off is worse than drift.

set -uo pipefail

# printf is a builtin: no forks, and nothing needed on PATH.
printf '%s\n' \
  '[nativish] Hook directive — control context, NOT text to coach. Apply the English coaching rule to the prompt that follows: a Mode 1 correction if it has real mistakes, a Mode 2 compliment if it is clean, or nothing at all if it matches a Mode 3 skip condition (ack, slash command, non-prose, non-Latin script, toggle marker). If coaching is off, coach nothing and say nothing about coaching.'
