#!/usr/bin/env bash
# SessionStart memory-attribution guard. Agent memory is keyed by the launch
# cwd, so a session started in the wrong place files memory under the wrong
# project. This hook classifies the launch location and, when it's wrong,
# instructs the agent to STOP and ask the user which project the work belongs
# to before doing anything substantive.
#
# Builtin parameter expansion only (no subprocess forks except git — this
# runs every session start). ${d##*/} differs from basename only for d="/".
d="$PWD"
b="${d##*/}"
# Claude Code encodes project dirs by replacing every non-alphanumeric char
# with '-' (verified against ~/.claude/projects). Match that convention.
p="${d//[^A-Za-z0-9]/-}"

status="ok"; reason=""
if [ "$d" = "$HOME" ]; then
  status="bad"; reason="session launched in the home directory — memory would be keyed to a junk label"
elif top="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null)"; then
  if [ "$top" != "$d" ]; then
    status="bad"; reason="launched in a SUBDIRECTORY of ${top##*/} — memory keys to the subdir, not the project"
  else
    # Optional per-machine convention: ~/.claude/project-roots lists preferred
    # parent dirs (one per line, ~ allowed). If present, repos outside them warn.
    roots_file="$HOME/.claude/project-roots"
    if [ -f "$roots_file" ]; then
      inroot="no"
      while IFS= read -r r; do
        [ -z "$r" ] && continue
        case "$r" in "~"*) r="$HOME${r#\~}";; esac
        case "$d" in "$r"/*) inroot="yes"; break;; esac
      done < "$roots_file"
      if [ "$inroot" = "no" ]; then
        status="warn"; reason="git repo outside your configured project roots ($(tr '\n' ' ' < "$roots_file"))"
      fi
    fi
  fi
else
  status="bad"; reason="not inside a git repository — no stable project identity"
fi

base_msg="📁 cwd: $d\n🏷  claude-mem project: [$b]  → ~/.claude/projects/$p/memory/"
if [ "$status" = "ok" ]; then
  msg="$base_msg"
  ctx="Session launched in $d; memory files under project label [$b] (memory dir ~/.claude/projects/$p/memory/)."
else
  icon="⚠️"; [ "$status" = "bad" ] && icon="🛑"
  msg="$icon MEMORY ATTRIBUTION: $reason\n$base_msg\n→ prefer: proj <name> claude (launches from the project root)"
  ctx="MEMORY ATTRIBUTION GUARD ($status): $reason. This session's memory is keyed to [$b] ($d). BEFORE doing substantive work, ask the user (via your blocking question tool) which project this work belongs to. Then: (a) if they can relaunch, suggest 'proj <name> claude' from the correct root; (b) if they continue here, write any memory files explicitly into the CORRECT project's directory under ~/.claude/projects/<encoded-path>/memory/ instead of this session's default, and say so. Do not silently accept the wrong attribution."
fi

jq -cn --arg m "$msg" --arg c "$ctx" '{
  systemMessage: ($m | gsub("\\\\n"; "\n")),
  hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: $c }
}'
