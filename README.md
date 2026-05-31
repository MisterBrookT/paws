# 🐾 Paws

> *Pause* when your agent needs you. *Play* while it works.

A terminal companion for AI coding agents. Paws gives you an immersive full-screen game to play while your agent is working — and auto-pauses when it needs your input.

Built for the overlooked moment in vibe coding: you want to stay near the terminal, but the agent is thinking and you have nothing to do.

## How it works

```
┌─────────────────────────────────────┐
│                                     │
│      🎮 Game (full screen)          │  ← agent is working, you play
│                                     │
│                                     │
└─────────────────────────────────────┘
         agent done → game pauses, overlay appears:

┌─────────────────────────────────────┐
│                                     │
│   ┌───────────────────────────┐     │
│   │  🐾 Agent done!           │     │
│   │  Press Enter to go back   │     │
│   │  Auto-return in 3...      │     │
│   └───────────────────────────┘     │
│                                     │
└─────────────────────────────────────┘
         user presses Enter (or countdown ends):

┌─────────────────────────────────────┐
│                                     │
│      🤖 Agent (full screen)         │  ← read output, respond
│                                     │
│                                     │
└─────────────────────────────────────┘
```

1. You start a coding session → Paws is ready in the background
2. You send a prompt, then press **CMD+G** → game zooms full screen
3. Agent finishes (stop hook) → game pauses, overlay shows "Agent done"
4. You press Enter (or wait 3s in auto mode) → switches back to agent
5. Repeat

## Architecture

```
paws (Rust binary)
├── wrapper TUI        — manages game lifecycle, pause overlay, countdown
├── game rotation      — picks a random game each session/interval
└── kaku integration   — zoom-pane for full-screen switching

kiro stop hook         — signals paws when agent is done
kaku lua config        — CMD+G keybinding
```

### The Rust Wrapper

A lightweight TUI (ratatui) that:
- Spawns and embeds a terminal game (2048, etc.) via PTY
- On "agent done" signal: pauses game, renders overlay with message + countdown
- On Enter / countdown end: triggers `kaku cli zoom-pane` to switch back to agent
- Listens for signals via a simple file watch or Unix socket

### Game Rotation

- Multiple games available (2048, sudoku, snake, word games, pet interactions, trivia)
- Each day (or every few hours), Paws randomly picks one
- Gives a sense of freshness and surprise
- User can also manually pick via a launcher menu

### Modes

| Mode | Behavior |
|------|----------|
| **Manual** (default) | Game pauses + overlay. User presses Enter to go back. |
| **Auto** | Game pauses + overlay with 3s countdown. Auto-switches back. |

## Requirements

- [Kaku terminal](https://github.com/tw93/kaku) (WezTerm fork)
- [Kiro CLI](https://kiro.dev) (primary) or Claude Code (planned)

## Install

```fish
# TODO: brew install paws (goal)
git clone https://github.com/MisterBrookT/paws.git
cd paws
./install.fish
```

## Usage

```fish
# Paws starts automatically with your agent session
# (or manually: paws start)

# Switch to game (full screen)
# Press CMD+G

# Agent finishes → auto-pauses game, shows overlay
# Press Enter to go back (or wait for auto-return)

# End session
paws stop
```

## Supported Agents

- **Kiro CLI** — via stop hook (primary, working)
- **Claude Code** — via notification hook (planned)

## Roadmap

- [x] Core: zoom-pane full-screen switching
- [x] Kiro stop hook integration
- [ ] Rust wrapper TUI with pause overlay + countdown
- [ ] Multi-game rotation (daily/hourly random pick)
- [ ] Pet mode (ambient companion that reacts to agent state)
- [ ] `brew install paws`
- [ ] Claude Code support
- [ ] Auto-start with Kaku (Lua startup hook)

## Design

Full design rationale in [`docs/design.tex`](docs/design.tex).

## License

MIT
