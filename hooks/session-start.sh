#!/usr/bin/env bash
set -euo pipefail

# Inject the writing-coach plugin's coaching rules into the conversation.
# Output goes to stdout, which Claude Code attaches as additional SessionStart context.

cat <<'HEADER'
=== nativish plugin: active ===

Apply the English coaching rule below to EVERY user message in this conversation.

HEADER

cat "${CLAUDE_PLUGIN_ROOT}/skills/english-coaching/SKILL.md"
