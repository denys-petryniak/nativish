#!/usr/bin/env bash
set -euo pipefail

# Inject the writing-coach plugin's coaching rules into the conversation.
# Output goes to stdout, which Claude Code attaches as additional SessionStart context.

cat <<'HEADER'
=== nativish plugin: active ===

Apply BOTH coaching rules below to EVERY user message in this conversation.
The English check runs by default; the Prompt coach runs only when enabled.

HEADER

cat "${CLAUDE_PLUGIN_ROOT}/skills/english-coaching/SKILL.md"
printf '\n---\n\n'
cat "${CLAUDE_PLUGIN_ROOT}/skills/prompt-coaching/SKILL.md"
