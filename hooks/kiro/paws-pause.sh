#!/bin/bash
# Paws stop hook: agent finished a turn → zoom agent pane to full screen.
# The user sees the agent output full-screen, ready to respond.

STATE_FILE="/tmp/paws-state.json"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

AGENT_PANE_ID=$(cat "$STATE_FILE" | grep -o '"agent_pane_id":[0-9]*' | grep -o '[0-9]*')

if [ -z "$AGENT_PANE_ID" ]; then
  exit 0
fi

# Zoom agent pane to full screen (user focuses on responding)
kaku cli activate-pane --pane-id "$AGENT_PANE_ID" >/dev/null 2>&1
kaku cli zoom-pane --pane-id "$AGENT_PANE_ID" --zoom >/dev/null 2>&1

exit 0
