#!/usr/bin/env fish
# paws - Terminal companion for AI coding agents
# Usage: paws start | paws stop | paws status | paws play

set STATE_FILE /tmp/paws-state.json
set GAME_CMD 2048

function paws_start
    if test -f $STATE_FILE
        echo "🐾 Paws is already running. Use 'paws play' to switch to game."
        return 1
    end

    # Get current pane id (agent pane)
    set agent_pane_id (kaku cli list --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for w in data:
    if w.get('is_active'):
        print(w['pane_id'])
        sys.exit()
for w in data:
    print(w['pane_id'])
    sys.exit()
" 2>/dev/null)

    if test -z "$agent_pane_id"
        echo "❌ Could not detect Kaku pane. Are you running inside Kaku?"
        return 1
    end

    # Create game pane (small split, will be zoomed to full screen when playing)
    set game_pane_id (kaku cli split-pane --bottom --percent 50 -- $GAME_CMD 2>/dev/null)

    if test -z "$game_pane_id"
        echo "❌ Failed to create game pane."
        return 1
    end

    # Write state
    echo "{\"game_pane_id\":$game_pane_id,\"agent_pane_id\":$agent_pane_id}" > $STATE_FILE

    # Zoom agent pane (start in work mode)
    kaku cli activate-pane --pane-id $agent_pane_id >/dev/null 2>&1
    kaku cli zoom-pane --pane-id $agent_pane_id --zoom >/dev/null 2>&1

    echo "🐾 Paws started! Game ready in background."
    echo "   Use 'paws play' (or CMD+G) to switch to game."
    echo "   When agent finishes, it auto-switches back here."
end

function paws_play
    if not test -f $STATE_FILE
        echo "🐾 Paws is not running. Use 'paws start' first."
        return 1
    end

    set game_pane_id (cat $STATE_FILE | python3 -c "import json,sys; print(json.load(sys.stdin)['game_pane_id'])" 2>/dev/null)

    # Zoom game pane to full screen
    kaku cli activate-pane --pane-id $game_pane_id >/dev/null 2>&1
    kaku cli zoom-pane --pane-id $game_pane_id --zoom >/dev/null 2>&1
end

function paws_stop
    if not test -f $STATE_FILE
        echo "🐾 Paws is not running."
        return 0
    end

    set game_pane_id (cat $STATE_FILE | python3 -c "import json,sys; print(json.load(sys.stdin)['game_pane_id'])" 2>/dev/null)

    if test -n "$game_pane_id"
        kaku cli kill-pane --pane-id $game_pane_id >/dev/null 2>&1
    end

    rm -f $STATE_FILE
    echo "🐾 Paws stopped."
end

function paws_status
    if test -f $STATE_FILE
        echo "🐾 Paws is running."
        cat $STATE_FILE | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(f'   Game pane: {d[\"game_pane_id\"]}')
print(f'   Agent pane: {d[\"agent_pane_id\"]}')
"
    else
        echo "🐾 Paws is not running."
    end
end

# Main
switch (count $argv) > 0; and echo $argv[1]; or echo "help"
    case start
        paws_start
    case stop
        paws_stop
    case play
        paws_play
    case status
        paws_status
    case '*'
        echo "🐾 Paws - Terminal companion for AI coding agents"
        echo ""
        echo "Usage:"
        echo "  paws start   Start game in background, stay in agent mode"
        echo "  paws play    Switch to game (full screen)"
        echo "  paws stop    Kill the game and clean up"
        echo "  paws status  Check if paws is running"
        echo ""
        echo "The game auto-hides when agent needs your input."
end
