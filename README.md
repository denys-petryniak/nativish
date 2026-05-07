# nativish

A writing coach plugin for [Claude Code](https://www.anthropic.com/claude-code) — corrects your English before every response, with optional prompt enhancement. Built for non-native speakers who code with Claude.

## Install

```bash
/plugin marketplace add denys-petryniak/nativish
/plugin install nativish@nativish
```

Restart your Claude Code session for the `SessionStart` hook to take effect.

## What it does

Two skills activate at session start.

### English coaching (on by default)

Before every response, Claude inspects your prompt:

- Real grammar, spelling, or word-choice mistakes → a corrected version plus a numbered list of fixes
- Clean prompt → a one-line compliment
- Slash command or short ack (`yes`, `ok`, `thanks`) → silent

Example output when fixes are needed:

```text
─── English check ───

**Corrected:** "..."

1. "<original>" → "<corrected>" — <issue>
2. ...

──────────────────────
```

Toggle:

- `coach:en off` — disable for the conversation
- `coach:en on` — re-enable

### Prompt coaching (off by default)

When enabled, Claude rewrites vague prompts into clearer, more specific ones — useful for learning to prompt better.

Toggle:

- `coach:prompt on` — enable
- `coach:prompt off` — disable

## How it works

A `SessionStart` hook injects both skill definitions into the conversation's system context, so the rules apply on every user message — no manual skill invocation needed.

## Why "nativish"?

A coined word — *almost native*. The plugin won't turn you into a native speaker, but it nudges your written English a little closer every conversation.
