# Nativish — repo conventions

Working notes for Claude Code sessions in this repo. Keep this file tight — only capture conventions that aren't derivable from the code or git history.

## Commits

- **Conventional Commits.** Common scopes: `english-coaching`, `readme`, `tests`. Common types: `feat`, `fix`, `test`, `docs`, `chore`.
- **Split commits by intent.** Feature, tests for the feature, and version bump go in *separate* commits. Look at the run-up to any release tag for the pattern.
- **No `Co-Authored-By` trailers.** Enforced via `.claude/settings.json` (`"includeCoAuthoredBy": false`).

## Release workflow

For each release:

1. Bump version in **both** `.claude-plugin/plugin.json` *and* `.claude-plugin/marketplace.json` — they must stay in sync.
2. Commit the bump as `chore: bump version to X.Y.Z` (separate commit, last in the release sequence).
3. Annotate the tag: `git tag -a vX.Y.Z -m "vX.Y.Z — <short summary>"`.
4. Push commits and tag together: `git push --follow-tags origin main`.
5. Create the GitHub Release: `gh release create vX.Y.Z --title "vX.Y.Z — <summary>" --notes "..."`. Use the `## Highlights` / `## What's new` / `**Full changelog**` structure from past releases.

Pushing a tag does **not** auto-create a GitHub Release. Both steps are required.

## Skill changes

Any change to `skills/english-coaching/SKILL.md` is gated by the adversarial fixture suite at `tests/adversarial-prompts.md`:

- Run `tests/run-fixtures.sh` before tagging a release — covers single-shot cases via `claude -p` + LLM-as-judge.
- Multi-step cases (T2, T3, ST6, ST7) and strict-mode-active cases (ST2–ST5) must still be run manually per the suite doc.
- New behavior requires a new fixture case in both `adversarial-prompts.md` and `run-fixtures.sh`. Group related cases under a `##` section — see `## Strict mode` for the pattern.
- Treat any deviation from the **Expected** column as a regression.

## Superpowers skills (when available)

If the `superpowers` plugin is loaded in your Claude Code session, prefer these skills for the workflows above:

- **`superpowers:writing-skills`** — before any edit to `skills/english-coaching/SKILL.md`. Catches frontmatter mistakes, missing when-to-trigger guidance, and other skill-authoring issues.
- **`superpowers:test-driven-development`** — pairs with the fixture suite. Add the new fixture case to `tests/adversarial-prompts.md` *before* the SKILL.md change, so the change is gated by a concrete expectation.
- **`superpowers:brainstorming`** — before designing any new feature (new state, toggle, output mode). The strict-mode design was a good fit; jumping straight to implementation would have skipped useful tradeoff discussion.
- **`superpowers:verification-before-completion`** — before tagging a release or claiming the suite passes. The fixture suite must actually be run, not just intended.

If superpowers isn't installed, the conventions above still apply.
