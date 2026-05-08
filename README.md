# Nativish

[![Latest release](https://img.shields.io/github/v/release/denys-petryniak/nativish?label=release&color=blue)](https://github.com/denys-petryniak/nativish/releases/latest)
[![License](https://img.shields.io/github/license/denys-petryniak/nativish?color=green)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-plugin-d97757?logo=anthropic&logoColor=white)](https://github.com/topics/claude-code-plugin)
[![Stars](https://img.shields.io/github/stars/denys-petryniak/nativish?style=flat&color=ffcb05)](https://github.com/denys-petryniak/nativish/stargazers)

A writing coach plugin for [Claude Code](https://www.anthropic.com/claude-code) — corrects your English before every response. Built for non-native speakers who code with Claude.

> ```text
> ─── English check ───
>
> **Corrected:** "I want to install this plugin from the marketplace."
>
> 1. "i want install" → "I want to install" — pronoun case + missing "to"
> 2. "from marketplace" → "from the marketplace" — missing article
>
> ──────────────────────
> ```
>
> *Every message you send gets coached, inline, before the answer.*

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

Toggle:

- `/nativish:off` — disable for the conversation (slash command, autocompletes after `/`)
- `/nativish:on` — re-enable
- Inline aliases: `nativish:off` / `nativish:on` (or with a space: `nativish off` / `nativish on`) — handy if you'd rather type than autocomplete. The marker must be the entire message, so pasting a doc that mentions `nativish:off` won't accidentally disable the coach.

While disabled, every reply shows `⏸ en-coach (off)` (instead of the active `✓ en-coach`) so you can tell at a glance whether the coach is paused or just had nothing to flag.

## How it works

A `SessionStart` hook injects the English-coaching skill into the conversation's system context, so the rule applies on every user message — no manual skill invocation needed.

## Why "Nativish"?

A coined word — *almost native*. The plugin won't turn you into a native speaker, but it nudges your written English a little closer every conversation.

---

*Made with Claude, for Claude.* 🧡
