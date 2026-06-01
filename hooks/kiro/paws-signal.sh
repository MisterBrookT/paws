#!/bin/bash
# Paws signal hook for Kiro: report the agent's state.
# Two channels (both idempotent):
#   1. File signal: /tmp/paws-signal (the Rust wrapper polls this)
#   2. OSC 1337 user-var (Kaku Lua user-var-changed handles tab switch)
# Usage: paws-pause.sh busy|done   (default: done)
state="${1:-done}"
echo "$state" > /tmp/paws-signal
printf '\033]1337;SetUserVar=paws_agent_%s=%s\007' "$state" "$(printf 1 | base64)" > /dev/tty 2>/dev/null
exit 0
