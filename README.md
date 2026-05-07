# nativish

A writing coach plugin for [Claude Code](https://www.anthropic.com/claude-code) — corrects your English before every response. Built for non-native speakers who code with Claude.

## Install

```bash
/plugin marketplace add denys-petryniak/nativish
/plugin install nativish@nativish
```

Restart your Claude Code session for the `SessionStart` hook to take effect.

## What it does

Before every response, Claude inspects your prompt:

- Real grammar, spelling, or word-choice mistakes → a corrected version plus a numbered list of fixes
- Clean prompt → a one-line compliment
- Slash command, short ack (`yes`, `ok`, `thanks`), or message in a non-Latin script → silent

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

## How it works

A `SessionStart` hook injects the English-coaching skill into the conversation's system context, so the rule applies on every user message — no manual skill invocation needed.

## Why "nativish"?

A coined word — *almost native*. The plugin won't turn you into a native speaker, but it nudges your written English a little closer every conversation.
