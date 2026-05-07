---
name: prompt-coaching
description: Use when prompt-coaching is enabled in the conversation — coaches the user's prompt before each response. Disabled by default; user enables with "coach:prompt on" and disables with "coach:prompt off".
---

# Prompt Coaching

When enabled, before every response coach the user's prompt. Pick one of two output modes, then proceed with the task.

## Output modes

```
Slash command, short ack, or already clear?  →  ✓ prompt-coach (skip)
Vague intent, missing context, or ambiguity?  →  Full block (enhanced + diff)
```

### Mode 1 — Full block

Use when the prompt would benefit from being clearer, more specific, or more complete.

```
─── Prompt coach ───

**Enhanced:** "..."

**What changed:**
1. ...
2. ...

──────────────────────
```

- **Enhanced prompt** — the user's message rewritten for Claude. Add missing context, reduce ambiguity, make intent explicit.
- **What changed** — 1–3 bullets naming the key improvements (e.g. "Specified expected output format", "Scoped to a single file", "Named the framework version").
- **Preserve intent** — enhance clarity, never change meaning. If the original is ambiguous between two readings, pick the more likely one and call out the assumption in "What changed".

### Mode 2 — Skip (just `✓ prompt-coach`)

Use when there's nothing to enhance. Show only `✓ prompt-coach` to confirm the rule is active.

- **Slash commands** — message starts with `/` (e.g. `/commit`, `/test`). The command text comes from the skill, not the user.
- **Short acknowledgments** — `yes`, `no`, `ok`, `sure`, `thanks`, `done`, `got it`, `sounds good`. Nothing to coach in a one- or two-word reply.
- **Already-clear prompts** — request is specific, scoped, and has the context Claude needs. Don't enhance for the sake of it.

## What to enhance

- **Vague verbs** — `fix this` → `fix the type error in useFoo.ts`.
- **Missing scope** — `refactor` → `refactor only composables/useAuth.ts, leave callers untouched`.
- **Implicit context** — `make it faster` → `reduce the bundle size of the dashboard route`.
- **Ambiguous targets** — `the form` → `the contact form on /about`.

## What NOT to enhance

- Cosmetic rewording that adds no information.
- Speculative requirements the user didn't ask for.
- Padding short prompts with filler.

## Toggle

- `coach:prompt on` — enable for this conversation.
- `coach:prompt off` — disable.
