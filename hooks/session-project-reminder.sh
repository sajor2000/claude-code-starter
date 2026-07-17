#!/usr/bin/env bash
# SessionStart hook: surface which directory the session opened in and which
# claude-mem project label / memory dir it maps to. Purely informational — the
# attribution itself is fixed by the launch cwd before any hook runs.
# Builtin parameter expansion (no subprocess forks — this runs every session
# start). ${d##*/} differs from basename only for d="/" (yields "" not "/"),
# acceptable for a display label.
d="$PWD"
b="${d##*/}"
# Claude Code encodes project dirs by replacing every non-alphanumeric char
# with '-' (verified against ~/.claude/projects: '.', '_' and '/' all become
# '-', e.g. .claude-mem -> --claude-mem). Match that convention exactly.
p="${d//[^A-Za-z0-9]/-}"
jq -cn --arg d "$d" --arg b "$b" --arg p "$p" '{
  systemMessage: ("📁 cwd: " + $d + "\n🏷  claude-mem project: [" + $b + "]  → ~/.claude/projects/" + $p + "/memory/"),
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: ("Session launched in " + $d + "; claude-mem files memory under project label [" + $b + "] (memory dir ~/.claude/projects/" + $p + "/memory/). If this work belongs to another repo, memory is still attributed to [" + $b + "].")
  }
}'
