#!/usr/bin/env bash
# Installs the session-project reminder hook into ~/.claude and wires it into
# settings.json (merging, never clobbering). Requires jq.
set -euo pipefail
command -v jq >/dev/null || { echo "jq required: brew install jq"; exit 1; }

mkdir -p "$HOME/.claude/hooks"
cp "$(dirname "$0")/hooks/session-project-reminder.sh" "$HOME/.claude/hooks/"
chmod +x "$HOME/.claude/hooks/session-project-reminder.sh"

S="$HOME/.claude/settings.json"
[[ -f "$S" ]] || echo '{}' > "$S"
HOOK_CMD="$HOME/.claude/hooks/session-project-reminder.sh"
if jq -e --arg c "$HOOK_CMD" \
  '.hooks.SessionStart[]?.hooks[]? | select(.command == $c)' "$S" >/dev/null 2>&1; then
  echo "hook already wired — nothing to do"
else
  tmp=$(mktemp)
  jq --arg c "$HOOK_CMD" \
    '.hooks.SessionStart = (.hooks.SessionStart // []) + [{"hooks":[{"type":"command","command":$c}]}]' \
    "$S" > "$tmp" && mv "$tmp" "$S"
  echo "hook wired into $S"
fi
echo "Done. Start a new Claude Code session to see the cwd→memory reminder."
