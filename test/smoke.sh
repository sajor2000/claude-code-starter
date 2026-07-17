#!/usr/bin/env bash
# Smoke tests for install.sh — the scenarios a real user hits.
# Run locally (./test/smoke.sh) or in CI.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
fresh() { T=$(mktemp -d); mkdir -p "$T/.claude"; }

# 1. fresh HOME: exactly one SessionStart entry
fresh; HOME="$T" bash "$ROOT/install.sh" >/dev/null
[ "$(jq '.hooks.SessionStart | length' "$T/.claude/settings.json")" = "1" ] || fail "fresh install"
rm -rf "$T"

# 2. idempotent re-run: still one entry
fresh; HOME="$T" bash "$ROOT/install.sh" >/dev/null; HOME="$T" bash "$ROOT/install.sh" >/dev/null
[ "$(jq '.hooks.SessionStart | length' "$T/.claude/settings.json")" = "1" ] || fail "idempotency"
rm -rf "$T"

# 3. zero-byte settings.json: seeded, not silently emptied
fresh; : > "$T/.claude/settings.json"; HOME="$T" bash "$ROOT/install.sh" >/dev/null
[ "$(jq '.hooks.SessionStart | length' "$T/.claude/settings.json")" = "1" ] || fail "empty-file seed"
rm -rf "$T"

# 4. tilde-spelled existing entry counts as wired (no double-fire)
fresh; printf '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"~/.claude/hooks/session-project-reminder.sh"}]}]}}' > "$T/.claude/settings.json"
HOME="$T" bash "$ROOT/install.sh" >/dev/null
[ "$(jq '.hooks.SessionStart | length' "$T/.claude/settings.json")" = "1" ] || fail "tilde dedupe"
rm -rf "$T"

# 5. merge preserves unrelated config and hooks
fresh; printf '{"model":"opus","hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"other.sh"}]}],"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"x"}]}]}}' > "$T/.claude/settings.json"
HOME="$T" bash "$ROOT/install.sh" >/dev/null
[ "$(jq -r '.model' "$T/.claude/settings.json")" = "opus" ] || fail "model clobbered"
[ "$(jq '.hooks.SessionStart | length' "$T/.claude/settings.json")" = "2" ] || fail "existing hook lost"
[ "$(jq '.hooks.PreToolUse | length' "$T/.claude/settings.json")" = "1" ] || fail "PreToolUse lost"
rm -rf "$T"

# 6. non-object settings.json rejected, file untouched
fresh; printf '[1,2]' > "$T/.claude/settings.json"
if HOME="$T" bash "$ROOT/install.sh" >/dev/null 2>&1; then fail "non-object accepted"; fi
[ "$(cat "$T/.claude/settings.json")" = "[1,2]" ] || fail "non-object file mutated"
rm -rf "$T"

# 7. hook emits valid JSON with both fields, from a dotted/underscored cwd
D=$(mktemp -d)/some.dotted_dir; mkdir -p "$D"; cd "$D"
bash "$ROOT/hooks/session-project-reminder.sh" > "$D/out.json"
jq -e '.systemMessage and .hookSpecificOutput.additionalContext' "$D/out.json" >/dev/null || fail "hook JSON"
jq -r '.systemMessage' "$D/out.json" | grep -q 'some-dotted-dir' || fail "hook label encoding"
cd /; rm -rf "$(dirname "$D")"

echo "all smoke tests passed"
