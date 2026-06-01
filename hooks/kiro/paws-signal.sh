#!/bin/bash
# Paws hook for Kiro: record this session's state + owning PID for the status HUD.
# Usage: paws-pause.sh busy|done   (default: done)
# The PID lets the HUD tell live sessions from closed ones. The write is atomic
# (temp file + rename) so the HUD never reads a half-written/empty file, which
# used to make a session briefly vanish from the counts during busy↔done flips.
state="${1:-done}"
dir=/tmp/paws-sessions
mkdir -p "$dir"

# Walk up the process tree to the owning `kiro-cli` process.
pid=$PPID
sid=0
while [ "${pid:-0}" -gt 1 ]; do
  if ps -o args= -p "$pid" 2>/dev/null | grep -q "kiro-cli"; then
    sid=$pid
    break
  fi
  pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
done

f="$dir/${KIRO_SESSION_ID:-default}"
tmp="$f.$$"
echo "$state $sid" > "$tmp" && mv -f "$tmp" "$f"
exit 0
