# Nativish

[![CI](https://github.com/denys-petryniak/nativish/actions/workflows/ci.yml/badge.svg)](https://github.com/denys-petryniak/nativish/actions/workflows/ci.yml) [![Latest release](https://img.shields.io/github/v/release/denys-petryniak/nativish?label=release&color=blue)](https://github.com/denys-petryniak/nativish/releases/latest) [![License](https://img.shields.io/github/license/denys-petryniak/nativish?color=green)](LICENSE) [![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-plugin-d97757?logo=anthropic&logoColor=white)](https://github.com/topics/claude-code-plugin) [![Stars](https://img.shields.io/github/stars/denys-petryniak/nativish?style=flat&color=ffcb05)](https://github.com/denys-petryniak/nativish/stargazers)

Checks your English before every reply in [Claude Code](https://www.anthropic.com/claude-code). Built for non-native speakers who code with Claude.

You type:

> the tests is failing after i update the config, can you explane why

Claude answers, with the fix on top:

> ✏️ The tests are failing after I updated the config. Can you explain why?<br>
> `the tests is` → `the tests are` subject-verb agreement<br>
> `i update` → `I updated` lowercase pronoun and tense<br>
> `explane` → `explain` spelling

Which config did you change? If it touched the test environment, that's the usual suspect — paste the failure and I'll look.

Grammar and meaning come first, spelling after. The missing `?`, the lowercase start, and shortcuts like `dont` or `pls` are chat style — never flagged.

Write it cleanly and you get one line instead:

> 💪 Sharp grammar — you're leveling up.

Slash commands, acks, version strings, bare paths and non-Latin text produce no output at all.

## Install

```bash
/plugin marketplace add denys-petryniak/nativish
/plugin install nativish@nativish
```

Restart your session so the hooks load.

## Toggle

| Command | Effect |
| --- | --- |
| `/nativish:off` | stop coaching for this conversation |
| `/nativish:on` | turn it back on |

Or send `nativish off` / `on` as a plain message.

## Privacy

Everything runs locally in two shell scripts. No network calls, no telemetry, nothing written to disk, and **no dependencies** — `cat` is the only external command either hook invokes, and the per-prompt one uses only builtins, so it runs with an empty `PATH`. Nothing to install means no supply chain to trust. Read all of it: [`hooks/`](hooks/), [`commands/`](commands/) and [`skills/english-coaching/`](skills/english-coaching/) — six files.

## Known limitations

- **A turn with real work in it** — `/tmp is full, please clean it` slips past unchecked on stronger models, because the reply goes straight to the task. Model-dependent, not by design.
- **Windows needs Git Bash** — hooks run through it. With only PowerShell available, the `.sh` hooks never execute and you get no coaching at all, silently.
- **Pasted code and logs** get coached too, so expect the odd false flag.
- **Toggles reset on `/clear`** — say `/nativish:off` again.
- **Long prompts** — the rewrite stops after a few sentences; fixes for the rest still appear.

---

*Nativish* — a coined word, *almost native*. It won't make you a native speaker, but it nudges your written English a little closer every conversation.

---

<p align="center"><em>Made with Claude, for Claude.</em> 🧡</p>
