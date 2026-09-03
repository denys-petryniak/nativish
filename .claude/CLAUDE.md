# Nativish — repo conventions

Working notes for Claude Code sessions in this repo. Keep this file tight — only capture conventions that aren't derivable from the code or git history.

## Architecture

Two hooks, one feature. The rules reach the model either once per session or on every prompt — there is no third option, since injecting them once from `UserPromptSubmit` would need on-disk state.

- `session-start.sh` injects the rulebook, on all five `SessionStart` sources. Its stdout becomes conversation context.
- `prompt-submit.sh` restates the rule before each response. It reads nothing and decides nothing.

The rulebook is the load-bearing half: probed, the reminder alone produces **zero** coaching, because the modes it names are defined nowhere else.

## Commits

- **Conventional Commits.** `git log` shows the types and scopes in use.
- **Split commits by intent.** Feature, tests for the feature, and version bump go in *separate* commits. Look at the run-up to any release tag for the pattern.
- **No `Co-Authored-By` trailers.** Enforced via `.claude/settings.json` (`"includeCoAuthoredBy": false`).

## Release workflow

For each release:

1. Bump `version` in `.claude-plugin/plugin.json` — the only place it lives. `marketplace.json` carries none, so there is nothing to keep in sync.
2. Commit the bump as `chore: bump version to X.Y.Z`, last in the sequence. If the manifest already carries it, tag directly — no empty bump commit.
3. Annotate the tag: `git tag -a vX.Y.Z -m "vX.Y.Z — <short summary>"`.
4. Push commits and tag together: `git push --follow-tags origin main`.
5. Create the GitHub Release: `gh release create vX.Y.Z --title "vX.Y.Z — <summary>" --notes "..."`. Use the `## Highlights` / `## What's new` / `**Full changelog**` structure from past releases.

Pushing a tag does **not** auto-create a GitHub Release. Both steps are required.

The fixture suite gates **tagging**, not merging.

## Skill changes

Any change to `skills/english-coaching/SKILL.md` is gated by the adversarial fixture suite at `tests/adversarial-prompts.md`:

- `tests/run-fixtures.sh` sandboxes itself and loads the working tree, not the installed release. `NATIVISH_TEST_MODEL` pins the model.
- **Results are model-dependent** — the same fixture passes on `haiku` and fails on the CLI default. Compare runs on one model or not at all.
- `SKIP` cases must be run by hand: `T2 T3 M2 H2 H3 ST2 ST5 ST6`.
- New behavior needs a case in both `adversarial-prompts.md` and `run-fixtures.sh` — diff their IDs to check.
- Treat any deviation from **Expected** as a regression — but check the harness first, which has invalidated three runs.

## Decisions — do not re-litigate

- **Two hooks, shell only.** Nowhere cheaper to put the rulebook.
- **The hook reminds, it does not classify.** It was a Mode 3 classifier once — JSON parser, path denylist, non-ASCII counter — and that was deleted, because the rulebook already specifies every mode. Fixtures cover them.
- **Zero external dependencies.** Not even `jq`; `cat` is the only external command either hook invokes.
- **No state on disk.** Toggles live in the conversation and reset on `/clear` — documented in the README, not fixed.
- **No user-specific tuning of the rulebook.** It would bake one L1 into an L1-agnostic tool.
- **Keep the rulebook lean.** Adding words to `SKILL.md` does not reliably change behaviour.

## Traps

Each of these failed silently, or reported success while measuring nothing.

- **A green suite can prove nothing.** The unit tests once invented a payload field and the hook read the same invented field, so every case passed against a hook that had never run. Test and implementation sharing one wrong assumption is the only bug a green suite cannot see.
- **`shellcheck` is not a parser.** It passed a file bash 3.2 refused to load — an apostrophe inside a heredoc nested in `$( )`. Run `bash -n` under `/bin/bash` as well.
- **Equal scores are not equivalence.** A rulebook-only versus rulebook-plus-reminder A/B came out even because the run was too shallow to induce any drift in either arm.
- **A sentinel that matches both branches passes vacuously.** An early suite used `Mode 3` as its skip marker, but that string also appeared in the coach directive.
- **GitHub collapses a multi-line blockquote.** Consecutive `>` lines are one CommonMark paragraph, so the newline is a soft break the browser renders as a space. The terminal keeps it, so the coaching block looks right in a session and wrong in the README and release notes — hard-break those with `<br>`.

## Superpowers skills (when available)

If the `superpowers` plugin is loaded in your Claude Code session, prefer these skills for the workflows above:

- **`superpowers:writing-skills`** — before any edit to `skills/english-coaching/SKILL.md`. Catches frontmatter mistakes, missing when-to-trigger guidance, and other skill-authoring issues.
- **`superpowers:test-driven-development`** — pairs with the fixture suite. Add the new fixture case to `tests/adversarial-prompts.md` *before* the SKILL.md change, so the change is gated by a concrete expectation.
- **`superpowers:brainstorming`** — before designing any new feature (new state, toggle, output mode). The strict-mode design was a good fit; jumping straight to implementation would have skipped useful tradeoff discussion.
- **`superpowers:verification-before-completion`** — before tagging a release or claiming the suite passes. The fixture suite must actually be run, not just intended.

If superpowers isn't installed, the conventions above still apply.
