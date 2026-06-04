# Changelog

All notable changes to Paws are documented here.

## [v0.5.0] — 2026-06-03

### Added
- **In-app game installer** — install any game from the picker without leaving the TUI; live progress log streams `cargo install` output line by line
- **4 new games**: Snake, 2048, Breakout, Space Invaders (7 games total)
- In-app installer progress screen with animated spinner, live log tail, and ✓/✗ result indicator

### Changed
- Game registry now includes all 7 games bundled by default
- Picker "⤓ Install games" tab replaces the old external install flow

## [v0.4.0] — 2026-06-03

### Added
- **WezTerm support** via `lua/paws.lua` Lua config
- **iTerm2 support** via Python AutoLaunch script (`iterm2/paws.py`)
- **tmux support** via shell scripts + `~/.tmux.conf` integration
- CI/CD workflow (build + clippy + fmt on macOS + Ubuntu)
- Issue templates and PR template
- `docs/ARCHITECTURE.md` — technical deep-dive

### Changed
- README overhauled: full terminal coverage table, per-agent install guide
- Kaku integration moved to `lua/paws.lua` (was inline)

## [v0.3.1] — 2026-06-03

### Added
- Dedicated in-app **Install games** catalog: browse the paws-games plugin index and install games from inside Paws
- Default game set: Dog Jump · Earth Online · Tetris

## [v0.3.0] — 2026-06-03

### Added
- Registry-based game discovery (`registry.toml`)
- Homebrew tap + formula (`interesting-vibe-coding/paws`)
- Multilingual UI (EN/ZH/JA/KO) via `src/lang.rs`
- HUD overlay on top row of PTY: shows session state, flashes on agent completion

[v0.5.0]: https://github.com/interesting-vibe-coding/paws/releases/tag/v0.5.0
[v0.4.0]: https://github.com/interesting-vibe-coding/paws/releases/tag/v0.4.0
[v0.3.1]: https://github.com/interesting-vibe-coding/paws/releases/tag/v0.3.1
[v0.3.0]: https://github.com/interesting-vibe-coding/paws/releases/tag/v0.3.0
