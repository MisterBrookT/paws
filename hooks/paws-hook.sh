#!/bin/bash
# Paws session hook — shared by Claude Code and Codex CLI.
# Writes session state to /tmp/paws-sessions/ so the Paws HUD can show
# how many AI agents are running/waiting.
#
# Usage: called as a command hook on PreToolUse (→ busy) and Stop (→ done).
# Receives JSON on stdin with at least { session_id, hook_event_name }.

set -euo pipefail

DIR="/tmp/paws-sessions"
mkdir -p "$DIR"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | grep -o '"session_id" *: *"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')
EVENT=$(echo "$INPUT" | grep -o '"hook_event_name" *: *"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')

[ -z "$SESSION_ID" ] && exit 0

PID=$$
case "$EVENT" in
  PreToolUse|SessionStart|UserPromptSubmit)
    STATE="busy"
    ;;
  Stop|SessionEnd)
    STATE="done"
    ;;
  *)
    STATE="busy"
    ;;
esac

# Atomic write (temp + rename) to prevent HUD flicker
TMP="$DIR/.tmp.$$"
echo "$STATE $PPID" > "$TMP"
mv "$TMP" "$DIR/$SESSION_ID"

exit 0
