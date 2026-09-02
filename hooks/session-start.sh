#!/usr/bin/env bash
set -euo pipefail

# Claude Code attaches this hook's stdout to the conversation as SessionStart
# context, which is how the rulebook reaches the model.

cat <<'HEADER'
=== nativish plugin: active ===

Apply the English coaching rule below to EVERY user message in this conversation.

HEADER

cat "${CLAUDE_PLUGIN_ROOT}/skills/english-coaching/SKILL.md"
