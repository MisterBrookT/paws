#!/bin/bash
# Paws hook for Kiro: record this session's state + owning PID for the status HUD.
# Usage: paws-pause.sh busy|done   (default: done)
# The PID lets the HUD tell live sessions from closed ones, so the game's own
# tab and already-closed sessions are never counted.
state="${1:-done}"
mkdir -p /tmp/paws-sessions

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

echo "$state $sid" > "/tmp/paws-sessions/${KIRO_SESSION_ID:-default}"
exit 0
