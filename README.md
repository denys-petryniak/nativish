# Nativish

[![Latest release](https://img.shields.io/github/v/release/denys-petryniak/nativish?label=release&color=blue)](https://github.com/denys-petryniak/nativish/releases/latest)
[![License](https://img.shields.io/github/license/denys-petryniak/nativish?color=green)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-plugin-d97757?logo=anthropic&logoColor=white)](https://github.com/topics/claude-code-plugin)
[![Stars](https://img.shields.io/github/stars/denys-petryniak/nativish?style=flat&color=ffcb05)](https://github.com/denys-petryniak/nativish/stargazers)

A writing coach plugin for [Claude Code](https://www.anthropic.com/claude-code) — corrects your English before every response. Built for non-native speakers who code with Claude.

![Nativish demo](https://github.com/denys-petryniak/nativish/releases/download/v0.5.2/nativish-demo.gif)

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

- `/nativish:off` — disable for the conversation
- `/nativish:on` — switch to default mode (chat-forgiving)
- `/nativish:strict` — switch to strict mode (also flags missing apostrophes, lowercase first letter, missing terminal periods, and common abbreviations)
- Inline aliases: `nativish:off` / `nativish:on` / `nativish:strict` (or with a space: `nativish off`, etc.) — handy if you'd rather type than autocomplete. The marker must be the entire message, so pasting a doc that mentions one of them won't accidentally switch states.

Status markers tell you which state the coach is in at a glance:

- `✓ en-coach` — default mode (active, chat-forgiving)
- `✓ en-coach (strict)` — strict mode (active, flags chat-style typos too)
- `⏸ en-coach (off)` — disabled

## How it works

A `SessionStart` hook injects the English-coaching skill into the conversation's system context, so the rule applies on every user message — no manual skill invocation needed.

## Privacy & security

Nativish is a self-contained Markdown + shell plugin:

- **No network calls** beyond the standard Anthropic API that Claude Code itself uses.
- **No telemetry**, no analytics, no external services.
- **No system file modifications** — the plugin only injects text into the conversation context via the `SessionStart` hook.
- **No elevated permissions required** — does not request bypass-permissions mode or any permission overrides.

The full installation is a few Markdown files and one shell script that `cat`s them. Inspect everything in [`hooks/`](hooks/) and [`skills/english-coaching/`](skills/english-coaching/).

## Known limitations

- **Model variance.** The skill's output format (Modes 1/2/3) is enforced via prose rules, so compliance varies by model. Opus follows the rules reliably; Sonnet (the default for many setups) occasionally drifts — wrapping a Mode 3 marker in dividers, or skipping the coaching block on a long input. The adversarial fixture suite at `tests/adversarial-prompts.md` catches drift; expect a high-but-not-perfect pass rate on Sonnet.
- **Pasted content gets coached too.** Code, logs, error messages, quoted prose — all of it is treated as text to check. Expect occasional false flags on snippets you didn't write.
- **Long prompts are truncated in `Corrected:`.** Only the first 2–3 sentences are echoed back; fixes for later sentences still appear in the numbered list below.

## Why "Nativish"?

A coined word — *almost native*. The plugin won't turn you into a native speaker, but it nudges your written English a little closer every conversation.

---

*Made with Claude, for Claude.* 🧡
