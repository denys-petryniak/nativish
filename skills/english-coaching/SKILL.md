---
name: english-coaching
description: Use when responding to ANY user message — coaches the user's English before each response. Enabled by default for non-native English speakers; user can toggle with "coach:en off" / "coach:en on".
---

# English Coaching

Before every response, coach the user's English. Pick one of three output modes, then proceed with the task.

## Output modes

```
Slash command or 1–2 word ack?  →  ✓ en-coach (skip)
Real mistakes to fix?            →  Full box (table)
Clean, or one-off typo?          →  One-line compliment
```

### Mode 1 — Full box

Use when the prompt has real mistakes (grammar, missing words, wrong word, proper-noun casing).

```
┌─ English check ─────

**Corrected prompt:** "..."

| # | Original | Corrected | Issue |
|---|---|---|---|
| ... |

└─────────────────────
```

- **Corrected prompt** — the user's message rewritten in correct English. For prompts of 3+ sentences, show only the first 2–3 corrected sentences if the rest is clean.
- **Table** — 2–5 rows, ordered by impact: grammar/meaning first, then spelling/articles.

### Mode 2 — Compliment

Use when the prompt is clean, or has only a one-off typo (single missing/swapped letter, finger-slip).

```
┌─ English check ─────

🌱 Strong English — keep growing.
_typo: "lets" → "let's"_

└─────────────────────
```

- Wrap the compliment in the same box as Mode 1, so the boundary between coaching and answer is always clear.
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

## What NOT to flag

These are chat style, not mistakes:

- **Lowercase first letter** — `is it useful?`
- **Missing terminal period**
- **Missing apostrophe in contractions** — `dont`, `cant`, `lets`
- **Common abbreviations** — `smth`, `wdyt`, `pls`, `tbh`, `imo`

**Do flag:** proper nouns and acronyms — `i` → `I`, `github` → `GitHub`, `eng` → `English`.

## Toggle

- `coach:en off` — disable for this conversation.
- `coach:en on` — re-enable.
