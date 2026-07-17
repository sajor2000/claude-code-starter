# claude-code-starter

A tiny, opinionated starter kit for a saner Claude Code (+ Codex) setup.

## What you get
- **Session-start reminder hook** — prints which directory your session
  opened in and which memory project it maps to, so misattributed agent
  memory is visible immediately. (`hooks/session-project-reminder.sh`)
- **AGENTS.md / CLAUDE.md templates** — the cross-tool pattern: put shared
  instructions in `AGENTS.md` (Codex/Cursor read it natively), and make
  `CLAUDE.md` a one-line `@AGENTS.md` import plus Claude-only extras.
- **settings-example.json** — how the hook wires into `~/.claude/settings.json`.

## Install
```sh
git clone https://github.com/sajor2000/claude-code-starter && cd claude-code-starter
./install.sh   # needs jq (brew install jq)
```
Then copy `templates/AGENTS.md` + `templates/CLAUDE.md` into any repo where
you run coding agents.

## Principles this encodes
1. **One projects root** (e.g. `~/Projects/<repo>`) — always launch agents
   from the repo root; stable cwd = correctly-attributed agent memory.
2. **AGENTS.md is canonical, CLAUDE.md imports it** — one instruction file,
   every tool.
3. **Hooks over habits** — the reminder fires every session so you don't
   have to remember to check.
