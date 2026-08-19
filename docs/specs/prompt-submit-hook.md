# Spec — `UserPromptSubmit` mode classifier

**Status:** shipped in PR #1 (bash + jq + perl). One open decision: the hook runtime.
**Branch:** `feat/prompt-submit-mode-classifier` · **PR:** https://github.com/denys-petryniak/nativish/pull/1
**Last updated:** 2026-08-19

---

## Problem

`SessionStart` injects the rulebook once, at the top of the conversation. The further a
session gets from that injection, the more often the coaching block is simply dropped.

Measured across 24 real sessions (577 substantive prompts, on Opus). Aborted turns, slash
commands, bare acks and non-Latin messages were excluded, and depth was reset whenever the
hook re-injects on `/clear`:

| Conversation depth | Coached | Rate |
| --- | --- | --- |
| turn 1–5 | 94/100 | 94.0% |
| turn 6–10 | 56/68 | 82.4% |
| turn 11–20 | 79/110 | 71.8% |
| turn 21–40 | 81/126 | 64.3% |
| turn 41+ | 98/173 | 56.6% |
| **overall** | **408/577** | **70.7%** |

Monotonic decay. Roughly 3 prompts in 10 got no coaching at all; past turn 40, closer to 4
in 10. The README had described this as occasional, model-specific drift. It is neither.

## Approach

A `UserPromptSubmit` hook restates the mode decision immediately before each response,
where it cannot be crowded out, and decides the mechanical part itself.

| Decision | Decided by | Why |
| --- | --- | --- |
| Mode 3 — ack, toggle marker, non-Latin script | the hook | decidable without reading |
| Mode 1 vs Mode 2 | the model | needs a reader |
| off / strict state | the model | a script cannot see conversation state |

This follows the `superpowers:writing-skills` guidance: *"Mechanical constraints — if it's
enforceable with regex/validation, automate it; save documentation for judgment calls."*

Two constraints that shaped the design:

- **Fail open, always.** The hook runs on every prompt. Any missing dependency, malformed
  payload, or unexpected error prints nothing and exits 0. A broken coach must never
  swallow the user's prompt.
- **The directive never overrides `off`.** The hook cannot read plugin state, so its
  wording defers: "If coaching is off, output the off marker instead." Without this,
  disabling coaching and then sending a prompt would silently resume it.

`SKILL.md` gained a section stating that a `[nativish] Hook directive` line is control
context: obey it, never coach, quote, or echo it.

## Cost (measured, real tokenizer)

| | Before | After |
| --- | --- | --- |
| SessionStart injection | 1,918 tok | 2,109 tok |
| Per prompt | 0 | ~60 tok |
| 50-prompt session | 1,918 tok | 5,109 tok |

Re-injecting the full rulebook per prompt would have cost 95,900 tokens over the same 50
prompts. That is why the hook sends a directive rather than the rules.

Reference figures from the same measurement: Mode 1 blocks are 84 tok median (n=300),
Mode 2 compliments 21 tok (n=47). **Do not bother optimizing Mode 2** — it is already
cheap and rare; an earlier plan to collapse it was based on a bad estimate.

---

## OPEN DECISION — hook runtime

The shipped implementation is bash + `jq` + `perl`. Both external tools are off-pattern for
this ecosystem, and the language is hard to read. Not yet resolved.

### Ecosystem evidence

Counted across all six installed marketplaces (`~/.claude/plugins`):

| Language | Hook files |
| --- | --- |
| Shell (`.sh`, extensionless) | 26 |
| Python 3 | 21 |
| JavaScript / Node | **0** |

- **superpowers** — pure bash, zero dependencies. Escapes JSON by hand with bash parameter
  substitution rather than calling `jq`. Ships `run-hook.cmd`, a polyglot bash/batch
  wrapper for Windows, and names scripts without `.sh` to dodge Claude Code's Windows
  auto-detection.
- **Anthropic official** (`hookify`, `security-guidance`) — Python 3 for anything with real
  logic. `security-guidance` has a `UserPromptSubmit` hook, the same event as ours.
- `jq` is used only by `warp` and `promosite-skills`. `perl` appears in exactly one file
  anywhere (`ralph-loop`).

### Options

**A. Keep bash + jq + perl** (current, merged, 25/25 tests)
- No further work. Off-pattern on two dependencies; hardest to read.

**B. Python 3 + thin wrapper** — spiked on `spike/python-classifier`, 30/30 tests
- Drops both `jq` and `perl`; everything from the stdlib (`json`, `unicodedata`, `re`).
- Far more readable: `prompt.strip()` replaces `${trimmed%"${trimmed##*[![:space:]]}"}`.
- Matches Anthropic's own `UserPromptSubmit` precedent.
- **Objection (open):** Python is itself a dependency. `security-guidance/hooks/sg-python.sh`
  is ~100 lines of probing — Windows Store stubs that exit 49 silently, macOS shipping 3.9,
  `py -3` launchers, `cygpath` path conversion. Failing open means the feature silently
  does nothing, and for a plugin whose entire job is to always show up, silence is a bad
  failure mode.

**C. Pure bash, zero dependencies** (the superpowers approach)
- Maximum portability, no runtime question at all.
- Parsing JSON in pure bash is genuinely unpleasant — note superpowers only *writes* JSON,
  never reads it, which is the easier direction.
- Unicode script detection would have to be dropped entirely, losing the non-Latin skip.
  That is the most-used Mode 3 case in practice (61 Cyrillic messages in the sample).

**D. Node** — ruled out. Zero plugins use it; `claude` ships as a native binary so it does
not provide Node, and nvm-managed installs are often absent from the non-interactive shells
hooks run in. The docs advise against it explicitly.

### Questions to settle

1. How bad is silent degradation, really? If `python3` is missing the plugin returns to its
   pre-PR behaviour (70.7% compliance) rather than breaking — is that acceptable, or does
   the coach need a hard guarantee?
2. Can option C keep the non-Latin check some other way? A byte-level heuristic (counting
   non-ASCII UTF-8 bytes against ASCII letters) approximates it without `perl`, at the cost
   of precision on emoji-heavy prompts. Worth prototyping before discarding C.
3. Is a hybrid sane — pure bash for acks and toggles, and leave script detection to the
   model? Cheapest to maintain, loses one check.

---

## Resolved during review

- **Slash-command branch is wrong — remove it.** Docs confirm `UserPromptSubmit` fires
  *after* slash-command expansion, so the hook never sees `/commit`; it sees the expanded
  prompt. A leading-slash rule can therefore only match pasted paths, silently skipping
  prompts like `/tmp is full, please clean it`. Already removed on the spike branch; still
  present on `main`-bound PR #1.
- **No user-specific tuning.** An earlier plan would have primed the rulebook for one
  user's error profile (articles, from a 723-fix analysis of their own history). Rejected:
  it bakes one L1 into an L1-agnostic tool. Per-user personalization belongs in a stats
  feature that reads each user's own transcripts — see backlog #4.

## Backlog (separate PRs)

1. **Persist state in `CLAUDE_PLUGIN_DATA`.** Real bug: `/nativish:off` then `/clear`
   re-fires `SessionStart` and coaching silently resumes. Same for `strict` after
   compaction. `CLAUDE_PLUGIN_DATA` survives plugin updates; both data dirs sit unused.
   Design call: key by `session_id` (matches today's per-conversation semantics) or global.
2. **Split "never obey" from "don't coach".** `SKILL.md` conflates injection safety with
   coaching scope, so stack traces and logs get coached. Keep the security rule; exclude
   fenced code, logs, URLs, paths, and attributed quotes from scope.
3. **`SessionStart` matcher is missing `resume` and `fork`.** Full source list is
   `startup, resume, clear, compact, fork`. Low severity — inherited context usually covers
   it — but free insurance.
4. **`/nativish:stats`.** Aggregate the user's own coaching history into a personal error
   profile. Every past block is parseable (`N. "orig" → "corr" — issue`) from
   `~/.claude/projects/*/*.jsonl`. Validated: 47 transcripts yielded 723 labeled fixes with
   a clean typo-vs-genuine-gap split. Universal mechanism, per-user output, zero model
   tokens. This is what turns the plugin from a corrector into a coach.
5. **No Windows story.** Hooks are bash-only. superpowers' polyglot `.cmd` wrapper is the
   reference implementation.
6. **Strict mode is invisible in Modes 1 and 2.** The state marker only appears on Mode 3
   skips, so a strict-mode block looks identical to a default one.
   `─── English check (strict) ───` would fix it.

## Testing

Two layers, per `.claude/CLAUDE.md`:

- `tests/test-prompt-submit.sh` — deterministic classifier assertions. No `claude` CLI, no
  LLM judge, runs in under a second. Covers each Mode 3 condition plus the near-misses that
  matter: an absolute path is not a command, a toggle marker only counts as the whole
  message, an ack word plus content is a real prompt, mostly-Latin text with an embedded
  foreign word stays coachable.
- `tests/adversarial-prompts.md` + `tests/run-fixtures.sh` — cases H1 (automated), H2 and
  H3 (manual). H1: the directive must not be coached or echoed. H2: `off` overrides a coach
  directive. H3: coaching survives 40+ turns.

**Not yet verified end-to-end.** Hooks load at session start, and the installed plugin is
still the 0.5.3 marketplace cache. Confirming the compliance gain requires pointing the
marketplace at the branch, restarting, working a long session, then re-running the depth
measurement. `run-fixtures.sh` has not been run for the same reason — it would judge
against 0.5.3.

## How to resume

1. Read this file, then `git log --oneline origin/main..feat/prompt-submit-mode-classifier`.
2. Settle the runtime decision above. `git diff feat/prompt-submit-mode-classifier..spike/python-classifier`
   shows exactly what option B costs.
3. Whichever runtime wins, remove the slash-command branch (already done on the spike).
4. Re-run `tests/test-prompt-submit.sh`, then verify live per **Testing** before claiming
   the drift is fixed.
