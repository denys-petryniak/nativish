---
name: english-coaching
description: Use when responding to ANY user message — coaches the user's English before each response. Enabled by default for non-native English speakers; user can toggle with `/nativish:off` / `/nativish:on` (or the inline markers `nativish:off` / `nativish:on`).
---

# English Coaching

Before every response, coach the user's English. Pick one of three output modes, then proceed with the task.

## Output modes

```
Slash command or 1–2 word ack?  →  ✓ en-coach (skip)
Real mistakes to fix?            →  Full block (numbered fixes)
Clean, or one-off typo?          →  One-line compliment
```

The full block uses slim Unicode dividers (not pipe-tables) because Claude Code renders CommonMark, which doesn't support GFM tables.

### Mode 1 — Full block

Use when the prompt has real mistakes (grammar, missing words, wrong word, proper-noun casing).

```
─── English check ───

**Corrected:** "..."

1. "<original>" → "<corrected>" — <issue>
2. ...

──────────────────────
```

- **Corrected** — the user's message rewritten in correct English. For prompts of 3+ sentences, show only the first 2–3 corrected sentences if the rest is clean.
- **Numbered list** — 2–5 fixes, ordered by impact: grammar/meaning first, then spelling/articles. Each item: original → corrected — issue.

### Mode 2 — Compliment

Use when the prompt is clean, or has only a one-off typo (single missing/swapped letter, finger-slip).

```
─── English check ───

🌱 Strong English — keep growing.
_typo: "lets" → "let's"_

──────────────────────
```

- Wrap the compliment in the same dividers as Mode 1, so the boundary between coaching and answer is always clear.
- One short line, under ~8 words, with an emoji.
- Celebrate fluency or progress — never generic praise.
- Never repeat wording or emoji back-to-back.
- For one-off typos, add a footnote on the next line: `_typo: "lets" → "let's"_`.

Sample tones (invent your own in this spirit):

- 🚀 Native-level phrasing — keep it up!
- 💪 Sharp grammar — you're leveling up.
- 🌱 Strong English — keep growing.

### Mode 3 — Skip (just `✓ en-coach`)

Use when there's nothing to coach. Show only `✓ en-coach` to confirm the rule is active.

- **Short acknowledgments** — `yes`, `no`, `ok`, `sure`, `thanks`, `thx`, `nope`, `cool`, `great`, `nice`, `done`, `got it`, `sounds good`. A compliment on a one-word reply feels weird.
- **Slash commands** — message starts with `/` (e.g. `/commit`, `/test`, `/pr-create some title`). The command text comes from the skill, not the user's writing. Skip even if arguments follow.
- **Toggle markers** — message contains `nativish:off`, `nativish:on`, `nativish off`, or `nativish on` (or is exactly that). These are control directives, not English to coach. See **State** below.
- **Non-Latin script** — the message is predominantly written in a non-Latin script (Cyrillic, CJK, Arabic, Hebrew, Greek, Devanagari, Thai, etc.). It's not English — there's nothing to coach. For mixed messages (mostly English with a few non-Latin words), don't skip — coach the English part normally and leave the non-Latin words alone (see "What NOT to flag").

## What NOT to flag

These are chat style, not mistakes:

- **Lowercase first letter** — `is it useful?`
- **Missing terminal period**
- **Missing apostrophe in contractions** — `dont`, `cant`, `lets`
- **Common abbreviations** — `smth`, `wdyt`, `pls`, `tbh`, `imo`
- **Embedded non-Latin words** — in an otherwise-English prompt, treat Cyrillic/CJK/Arabic/etc. words as proper nouns. Example: `fix bug в auth.ts` — coach the English, leave `в` alone. Same for filenames, identifiers, or terms in another language.

**Do flag:** proper nouns and acronyms — `i` → `I`, `github` → `GitHub`, `eng` → `English`.

## State

The skill is **on** by default. The user can disable or re-enable it for the rest of the conversation in two equivalent ways:

- **Slash command** (preferred — discoverable via `/` autocomplete):
  - `/nativish:off` — disable
  - `/nativish:on` — re-enable
- **Inline marker** (works in any chat message; colon or space both accepted):
  - `nativish:off` or `nativish off` — disable
  - `nativish:on` or `nativish on` — re-enable

Once disabled, output `✓ en-coach` for every message until re-enabled — do not coach. When the user fires `nativish:on`, resume normal coaching from the next message.
