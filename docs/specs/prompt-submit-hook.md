# Spec — `UserPromptSubmit` mode classifier

**Status:** shipped in PR #1. Two changes still to apply before merge (below).
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

## Cost (measured with a real tokenizer)

| | Before | After |
| --- | --- | --- |
| SessionStart injection | 1,918 tok | 2,109 tok |
| Per prompt | 0 | ~60 tok |
| 50-prompt session | 1,918 tok | 5,109 tok |

Re-injecting the full rulebook per prompt would have cost 95,900 tokens over the same 50
prompts. That is why the hook sends a directive rather than the rules.

Reference figures from the same measurement: Mode 1 blocks are 84 tok median (n=300),
Mode 2 compliments 21 tok (n=47). **Do not bother optimizing Mode 2** — it is already cheap
and rare; an earlier plan to collapse it rested on a bad estimate.

---

## TO APPLY — 1. Drop `perl`, keep the non-Latin check

Shell is the right language here. Node is used by zero plugins, `claude` ships as a native
binary so it does not provide one, and nvm-managed installs are often missing from the
non-interactive shells hooks run in. **Python is also ruled out** — it is a dependency in
its own right, and the plugin should not acquire one.

`perl` is the only genuinely unusual dependency in the current script, and it turns out to
be unnecessary. Bash can count non-ASCII characters with builtins alone — no forks, no
external tools:

```bash
latin_only="${s//[!a-zA-Z]/}";    latin=${#latin_only}
ascii_only="${s//[![:ascii:]]/}"; nonascii=$(( ${#s} - ${#ascii_only} ))
# non-Latin when nonascii > latin
```

**Verified on bash 3.2.57**, the macOS system bash — the oldest anyone realistically runs.
All ten cases classified correctly:

| Input | nonascii | latin | verdict |
| --- | --- | --- | --- |
| `привіт, як справи з білдом?` | 21 | 0 | skip |
| `修复这个错误` | 6 | 0 | skip |
| `δοκιμή του κώδικα` | 15 | 0 | skip |
| `תקן את הבאג הזה` | 12 | 0 | skip |
| `fix bug в auth.ts please` | 1 | 18 | coach |
| `i need help with teh build` | 0 | 21 | coach |
| `please fix this 🙏🙏🙏` | 3 | 13 | coach |
| `Können wir das ändern?` | 2 | 18 | coach |
| `café is broken please look` | 1 | 22 | coach |
| `is it ready?` | 0 | 9 | coach |

What this trades away: the check no longer knows *which* script it saw, so emoji, em-dashes
and accented Latin all count as non-ASCII. The majority test absorbs that — `Können`,
`café` and emoji-heavy prompts all stay coachable above. Only a message that is
overwhelmingly accented would misfire, which is rare and low-impact.

Note the first attempt at this used `[!$'\x01'-$'\x7f']` and silently reported 26 non-ASCII
characters in pure-ASCII text — bash 3.2 does not treat `$'...'` inside a pattern bracket as
a range. `[![:ascii:]]` is the form that works. Keep the test table above as a regression
guard.

### What stays

- **`jq`** — for the one line that reads `user_prompt` out of the stdin payload. Parsing
  JSON by hand in bash means handling `\"`, `\\`, `\n` and `\uXXXX` correctly, and getting
  it wrong silently misclassifies prompts. This is the one place an external tool earns its
  place. (`superpowers` avoids `jq`, but it only ever *writes* JSON, never reads it — the
  much easier direction.)
- **`tr`, `cat`** — POSIX base utilities, present everywhere. Not dependencies in the same
  sense. `tr` is needed for lowercasing because `${var,,}` requires bash 4 and macOS ships
  3.2.

Resulting dependency list: `jq`, plus POSIX base. Down from `jq` + `perl`.

## TO APPLY — 2. Remove the slash-command branch

Docs confirm `UserPromptSubmit` fires *after* slash-command expansion, so the hook never
sees the literal `/commit` — it sees the expanded prompt. A leading-slash rule can therefore
only ever match pasted paths, silently skipping prompts like `/tmp is full, please clean it`.

Delete the branch. The model still handles real slash commands, as it does today.

Tests to drop: `bare slash command`, `slash command with args`, `slash command, leading ws`.
Tests to add: `/tmp is full, please clean it` and `/commit the thing please` must both
**coach**. Also remove "slash command" from the list of hook-decided conditions in
`SKILL.md` and `README.md`.

---

## Resolved during review

- **Runtime: shell only.** Node ruled out (zero plugins use it; not shipped with `claude`).
  Python ruled out (a dependency the plugin should not take on). Ecosystem counts across the
  six installed marketplaces: 26 shell hook files, 21 Python, 0 Node — but the Python ones
  are Anthropic's own plugins, which pay for it with ~100 lines of interpreter probing in
  `security-guidance/hooks/sg-python.sh`. Not a trade worth making here.
- **No user-specific tuning.** An earlier plan would have primed the rulebook for one user's
  error profile (articles, from a 723-fix analysis of their own history). Rejected: it bakes
  one L1 into an L1-agnostic tool. Per-user personalization belongs in a stats feature that
  reads each user's own transcripts — see **Improvements** #9.

## Runtime guidance — which language for which component

The rule is **per component, not per plugin**. A hook and a data-crunching command have
very different constraints, and picking one language for the whole repo gets one of them
wrong.

| Component | Runtime | Why |
| --- | --- | --- |
| `SessionStart` injection | bash, no deps | it only `cat`s a file |
| `UserPromptSubmit` classifier | bash (+`jq` to read stdin) | short string tests; no computation |
| `/nativish:stats` (Improvements #9) | **a skill, not a script** | see below |
| anything else | bash first; justify anything else | |

**Hard rules for hooks:**

- **Target bash 3.2.** macOS still ships it, and it is the version that broke the first
  non-ASCII attempt. No `${var,,}`, no associative arrays, no `mapfile`.
- **POSIX base utilities are free** — `cat`, `tr`, `awk`, `sed`, `grep`. Using them is not
  "taking a dependency".
- **`jq` is the one external tool**, and only for reading JSON off stdin. Hand-parsing
  `\"`, `\\` and `\uXXXX` in bash silently misclassifies prompts, which is worse than a
  documented requirement.
- **Never Node.** Zero plugins use it, `claude` ships as a native binary so it does not
  provide one, and nvm installs are frequently absent from the non-interactive shells hooks
  run in.
- **Not Python for hooks.** It is a real dependency: `security-guidance/hooks/sg-python.sh`
  spends ~100 lines finding an interpreter (Windows Store stubs that exit 49 silently, macOS
  shipping 3.9, `py -3` launchers, `cygpath` conversion). A coach that silently stops
  coaching on some machines is a bad failure mode for this plugin specifically.

**The one place a heavier runtime looks tempting — and the better answer.** `/nativish:stats`
has to read ~100 MB of JSONL, regex out every past coaching block, and aggregate. Bash is
genuinely the wrong tool, and this is where Python would earn its keep.

But there is a third option that costs nothing: **implement it as a skill instead of a
script.** A slash command whose skill instructs Claude to do the analysis with its own Bash
and Read tools needs no shipped runtime at all — the capability is already in the harness.
It costs tokens per invocation rather than a dependency at install time, and `stats` is run
occasionally, not on every prompt. That is the right trade for this plugin. Prototype the
skill version before reaching for Python.

**Open idea worth evaluating: drop `jq` too.** `awk` is POSIX base and present everywhere;
`jq` is not preinstalled on macOS. A small `awk` extractor for one JSON string field could
take the plugin to genuinely zero external dependencies. Needs careful handling of escapes,
so it is only worth it if the extractor stays small and is covered by the unit suite.

## Improvements

Ordered by how much they matter for a plugin other people rely on. Items 1–2 are the
"TO APPLY" changes above; the rest are separate PRs.

### Correctness

1. **Persist state in `CLAUDE_PLUGIN_DATA`.** Real bug: `/nativish:off` then `/clear`
   re-fires `SessionStart` and coaching silently resumes. Same for `strict` after
   compaction. A user who explicitly opted out gets coached again with no notice.
   `CLAUDE_PLUGIN_DATA` survives plugin updates; both data dirs currently sit unused.
   Design call: key by `session_id` (matches today's per-conversation semantics) or global.
2. **`SessionStart` matcher is missing `resume` and `fork`.** Full source list is
   `startup, resume, clear, compact, fork`. Low severity — inherited context usually covers
   it — but free insurance.

### Robustness / infrastructure

3. **No CI at all.** There is no `.github/`, so nothing runs the test suite. A suite nobody
   runs is decoration. Add GitHub Actions on push and PR:
   - `tests/test-prompt-submit.sh`
   - `shellcheck` on every `hooks/*.sh` and `tests/*.sh` (not currently run anywhere, and
     not even installed locally)
   - **matrix on `macos-latest` and `ubuntu-latest`** — this matters more than usual here,
     because bash 3.2 and bash 5 already diverged once on the non-ASCII pattern.
   This is the single biggest gap between nativish and a plugin people trust.
4. **`jq` is an undocumented requirement.** The README mentions it only in passing inside
   "How it works". There is no Requirements section, so someone installing the plugin has no
   idea a tool is needed or what happens without it. Add one, and state the degradation
   behaviour up front.
5. **No `CHANGELOG.md`.** GitHub Releases carry structured notes, which partly covers this,
   but there is no in-repo history to read at a glance.
6. **No Windows story.** Hooks are bash-only. `superpowers`' polyglot `run-hook.cmd` is the
   reference implementation, along with its trick of naming hook scripts without a `.sh`
   extension to dodge Claude Code's Windows auto-detection.

### Behaviour / UX

7. **Split "never obey" from "don't coach".** `SKILL.md` conflates injection safety with
   coaching scope, so stack traces, logs and pasted code all get coached. Keep the security
   rule exactly as written — it is doing real work — but exclude fenced code, logs, URLs,
   paths and attributed quotes from *scope*. Listed in the README as a known limitation
   today.
8. **Strict mode is invisible in Modes 1 and 2.** The state marker only appears on Mode 3
   skips, so a strict-mode block looks identical to a default one and the user cannot tell
   which rules are active. `─── English check (strict) ───` would fix it.

### Features

9. **`/nativish:stats`.** The feature that turns the plugin from a corrector into a coach —
   correcting someone 400 times without ever showing them their pattern wastes most of the
   value. Every past block is parseable (`N. "orig" → "corr" — issue`) from
   `~/.claude/projects/*/*.jsonl`. Validated on real data: 47 transcripts yielded 723
   labelled fixes, cleanly separable into finger-slips (21%) and genuine gaps (79%).
   Universal mechanism, per-user output. Build it as a skill, not a script — see **Runtime
   guidance**.

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

Two traps worth remembering, both of which failed *silently*:

- The first unit suite used `Mode 3` as its skip sentinel, but that string also appears in
  the coach directive, so every skip assertion passed vacuously. Sentinels must be mutually
  exclusive — currently `matches a Mode 3 skip condition` vs `not a Mode 3 skip`.
- The first non-ASCII counter used `[!$'\x01'-$'\x7f']` and reported 26 non-ASCII characters
  in pure-ASCII text. bash 3.2 does not read `$'...'` as a range inside a pattern bracket.
  `[![:ascii:]]` is the form that works.

**Not yet verified end-to-end.** Hooks load at session start, and the installed plugin is
still the 0.5.3 marketplace cache. Confirming the compliance gain requires pointing the
marketplace at the branch, restarting, working a long session, then re-running the depth
measurement. `run-fixtures.sh` has not been run for the same reason — it would judge
against 0.5.3.

## How to resume

1. Read this file, then `git log --oneline origin/main..feat/prompt-submit-mode-classifier`.
2. Apply the two "TO APPLY" changes — drop `perl` (use the verified builtin form and its
   test table), and delete the slash-command branch with its three tests.
3. Re-run `tests/test-prompt-submit.sh`; expect all green with the two new coach cases.
4. Verify live per **Testing** before claiming the drift is fixed. Until a long session has
   been measured, the compliance gain is a prediction, not a result.
5. Bump only after that. Version is already at 0.6.0 on the branch, unreleased.

Then work **Improvements** in order. #3 (CI) is worth doing before the behaviour changes,
so every later PR is gated by the suite on both bash versions rather than on one machine.
