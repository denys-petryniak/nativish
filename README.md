# Nativish

[![CI](https://github.com/denys-petryniak/nativish/actions/workflows/ci.yml/badge.svg)](https://github.com/denys-petryniak/nativish/actions/workflows/ci.yml) [![Latest release](https://img.shields.io/github/v/release/denys-petryniak/nativish?label=release&color=blue)](https://github.com/denys-petryniak/nativish/releases/latest) [![License](https://img.shields.io/github/license/denys-petryniak/nativish?color=green)](LICENSE) [![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-plugin-d97757?logo=anthropic&logoColor=white)](https://github.com/topics/claude-code-plugin) [![Stars](https://img.shields.io/github/stars/denys-petryniak/nativish?style=flat&color=ffcb05)](https://github.com/denys-petryniak/nativish/stargazers)

Corrects your English before every reply in [Claude Code](https://www.anthropic.com/claude-code). Built for non-native speakers who code with Claude.

> ✏️ I need help with the build.<br>
> `i` → `I` lowercase pronoun<br>
> `teh` → `the` typo

Sure — what's failing? Paste the error output and I'll take a look.

Clean prompt? Just the one line:

> 💪 Sharp grammar — you're leveling up.

## Install

```bash
/plugin marketplace add denys-petryniak/nativish
/plugin install nativish@nativish
```

Restart your session so the hooks load.

## Toggle

| Command | Effect |
| --- | --- |
| `/nativish:off` | stop coaching |
| `/nativish:on` | back to normal — forgiving about chat style (`dont`, `pls`, lowercase starts) |
| `/nativish:strict` | flag chat style too |

Type `nativish off` / `on` / `strict` as a whole message if you'd rather not autocomplete. Slash commands, short acks (`ok`, `thanks`) and non-Latin messages are skipped silently.

## Privacy

Everything runs locally in two shell scripts. No network calls, no telemetry, nothing written to disk, and **no dependencies** — bash and POSIX utilities only, so there's no supply chain to trust. Read the whole thing in [`hooks/`](hooks/) and [`skills/english-coaching/`](skills/english-coaching/).

## Known limitations

- **Command-shaped prompts** — `dont forget to commit` often gets no check. The trigger is imperative form, not length.
- **Pasted code and logs** get coached too, so expect the odd false flag.
- **Toggles reset on `/clear`** — say `/nativish:off` again.
- **Long prompts** echo only the first 2–4 corrected sentences; the rest of the fixes still appear.

---

*Nativish* — a coined word, *almost native*. It won't make you a native speaker, but it nudges your written English a little closer every conversation.

---

<p align="center"><em>Made with Claude, for Claude.</em> 🧡</p>
