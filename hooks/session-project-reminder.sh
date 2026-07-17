#!/usr/bin/env bash
# SessionStart hook: surface which directory the session opened in and which
# claude-mem project label / memory dir it maps to. Purely informational — the
# attribution itself is fixed by the launch cwd before any hook runs.
d="$(pwd)"
b="$(basename "$d")"
p="$(printf '%s' "$d" | sed 's#/#-#g; s#_#-#g')"
jq -cn --arg d "$d" --arg b "$b" --arg p "$p" '{
  systemMessage: ("📁 cwd: " + $d + "\n🏷  claude-mem project: [" + $b + "]  → ~/.claude/projects/" + $p + "/memory/"),
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: ("Session launched in " + $d + "; claude-mem files memory under project label [" + $b + "]. If this work belongs to another repo, memory is still attributed to [" + $b + "].")
  }
}'
