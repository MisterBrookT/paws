# 🐾 Paws

> *Pause* when your agent needs you. *Play* while it works.

A terminal companion for AI coding agents. Paws opens a side-pane game in your terminal that **auto-pauses when your agent needs input** and resumes when you're done.

Built for the overlooked moment in vibe coding: you want to stay near the terminal, but the agent is thinking and you have nothing to do.

## How it works

```
┌─────────────────────────────────────┐
│                                     │
│         🎮 Game (full screen)       │  ← agent is working, you play
│                                     │
└─────────────────────────────────────┘
              agent done ↓ auto-switch
┌─────────────────────────────────────┐
│                                     │
│       🤖 Agent (full screen)        │  ← respond to agent
│                                     │
└─────────────────────────────────────┘
```

1. `paws start` → game launches in background
2. `paws play` (or CMD+G) → game zooms full screen, you play
3. Agent finishes → auto-zooms back to agent, full screen
4. You respond, agent starts working → switch back to game

## Requirements

- [Kaku terminal](https://github.com/tw93/kaku) (WezTerm fork with full CLI control)
- [fish shell](https://fishshell.com/) (scripts are in fish; bash port welcome)
- A terminal game (e.g. `2048-cli` — `brew install 2048`)

## Install

```fish
# Clone
git clone https://github.com/MisterBrookT/paws.git
cd paws

# Install the launcher + hook
./install.fish
```

## Usage

```fish
# Start paws (game launches in background)
paws start

# Switch to game full screen
paws play    # or press CMD+G

# Agent auto-switches back when it needs input

# Done for the day
paws stop
```

## Supported agents

- **Kiro CLI** — via hooks (primary)
- **Claude Code** — via notification hooks (planned)

## Project structure

```
paws/
├── bin/paws.fish          # Main launcher script
├── hooks/                 # Agent hook scripts
│   └── kiro/             # Kiro-specific hooks
├── lua/paws.lua          # Kaku Lua config snippet
├── docs/design.tex       # Original design document
├── install.fish          # Installer
└── README.md
```

## Design

The full design rationale (problem space, ecosystem survey, technical architecture) is in [`docs/design.tex`](docs/design.tex).

Key insight: Kaku's `kaku cli` **is** the IPC layer — no custom sockets, no Rust code, no tmux. The entire implementation is a fish script + a hook + a Lua snippet.

## License

MIT
