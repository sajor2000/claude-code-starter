#!/usr/bin/env bash
# Installs the session-project reminder hook into ~/.claude and wires it into
# settings.json (merging, never clobbering). Requires jq.
set -euo pipefail
command -v jq >/dev/null || { echo "jq required: brew install jq (macOS) / apt install jq (Linux)"; exit 1; }

HOOK_CMD="$HOME/.claude/hooks/session-project-reminder.sh"
mkdir -p "$HOME/.claude/hooks"
cp "$(dirname "$0")/hooks/session-project-reminder.sh" "$HOOK_CMD"
chmod +x "$HOOK_CMD"

S="$HOME/.claude/settings.json"
# -s (non-empty), not -f: a zero-byte settings.json must be seeded too,
# otherwise jq reads empty input, emits nothing, and we'd "succeed" into
# installing an empty file.
[[ -s "$S" ]] || echo '{}' > "$S"
# Refuse to merge into anything that isn't a single JSON object — a corrupt
# or multi-document file would be silently mangled otherwise.
jq -e 'type == "object"' "$S" >/dev/null 2>&1 \
  || { echo "error: $S is not a single JSON object — fix it, then re-run" >&2; exit 1; }
# Dedupe on the basename, not the exact string: an existing entry spelled
# "~/.claude/hooks/..." (as older docs showed) must count as already wired,
# or the hook fires twice per session.
if jq -e \
  '.hooks.SessionStart[]?.hooks[]? | select((.command // "") | endswith("/session-project-reminder.sh") or . == "~/.claude/hooks/session-project-reminder.sh")' \
  "$S" >/dev/null 2>&1; then
  echo "hook already wired — nothing to do"
else
  tmp=$(mktemp)
  jq --arg c "$HOOK_CMD" \
    '.hooks.SessionStart = (.hooks.SessionStart // []) + [{"hooks":[{"type":"command","command":$c}]}]' \
    "$S" > "$tmp" && mv "$tmp" "$S"
  echo "hook wired into $S"
fi
echo "Done. Start a new Claude Code session to see the cwd→memory reminder."
