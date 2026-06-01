---
name: paws-install
description: Install Paws 🐾 (terminal companion for AI coding agents) into the user's Kaku terminal and their agent (Kiro CLI or Claude Code). Use this when the user asks to install, set up, or wire up Paws. Performs the Kaku Lua merge, game install, and agent stop-hook wiring — all idempotently.
---

# Installing Paws 🐾

You are installing Paws for the user. Work from a local clone of this repo
(`paws/`). Do each step, verify, and report what you changed. All edits must be
**idempotent** — re-running must not duplicate anything.

## 0. Preconditions

- Confirm the terminal is **Kaku** (`which kaku`). If not, tell the user Paws
  currently requires Kaku and stop.
- Note the repo root (absolute path) — you'll need absolute paths later.

## 1. Install a game

The game tab runs `paws`, a tiny Rust launcher that shows a centered menu of
installed games (plus 🎲 Random rotation and a ⚙ Settings screen). Build it and
install some games:

```bash
cargo install --path .                                          # builds `paws` onto PATH
cargo install --git https://github.com/MisterBrookT/paws-games  # Jump High, Pinball, Earth Online, Knowledge
brew install vitetris                                           # optional: Tetris
paws --list                                                     # confirm which games are detected
```

If `cargo` is missing, point the user to https://rustup.rs first.

## 2. Merge the Lua into the Kaku config

The Kaku config is `~/.config/kaku/kaku.lua` (it returns a `config` table at the
end). The snippet to insert is `lua/paws.lua` from this repo.

- If `kaku.lua` already contains `Paws 🐾` (the marker comment), skip — already installed.
- Otherwise insert the **body** of `lua/paws.lua` (everything except its
  `local wezterm = require 'wezterm'` line, which the config already has)
  **immediately before** the final `return config` line.
- Ensure `config.keys` exists before the insert: if the config never sets it,
  add `config.keys = config.keys or {}` at the top of the inserted block.
- Syntax-check afterward: `luac -p ~/.config/kaku/kaku.lua` (if `luac` exists).

## 3. Wire the agent's state signals (for the status HUD)

`hooks/kiro/paws-signal.sh busy|done` records this session's state to
`/tmp/paws-sessions/<id>` so the game's HUD can show which agents are running vs
done. Wire two hooks: `userPromptSubmit` → `busy` (started) and `stop` → `done`
(finished). It does NOT move you around — switching is always manual (CMD+G).
**Use absolute paths** — `~` is not expanded in hook commands.

### Kiro CLI
`kiro_default` is built-in and cannot be edited, so use a custom agent identical
to default except for the hooks:

1. Create/merge `~/.kiro/agents/default.json` with:
   ```json
   {
     "name": "default",
     "tools": ["*"],
     "allowedTools": ["@builtin", "@*"],
     "useLegacyMcpJson": true,
     "hooks": {
       "userPromptSubmit": [{ "command": "<REPO>/hooks/kiro/paws-signal.sh busy" }],
       "stop": [
         { "command": "<REPO>/hooks/kiro/paws-signal.sh done" },
         { "command": "afplay /System/Library/Sounds/Glass.aiff" }
       ]
     }
   }
   ```
   The second `stop` hook is an optional completion chime (macOS). If the file
   exists, just add the hook entries (don't clobber other keys or existing hooks).
2. Tell the user to launch with `kiro-cli chat --agent default` (or update their
   shell alias) so the hooks are active.

### Claude Code (secondary / optional)
Add `Stop` / `UserPromptSubmit` hooks in the user's Claude settings that run the
same `paws-signal.sh done|busy`. (Claude support is still being validated.)

## 4. Make the signal script executable

```bash
chmod +x <REPO>/hooks/kiro/paws-signal.sh
```

## 5. Finish

Tell the user to **reload Kaku (CMD+Shift+R)** — Kaku does NOT auto-reload — then:
- **CMD+G** — opens the game tab (a centered menu: games · 🎲 Random · ⚙ Settings); after that it toggles agent ↔ game.
- **CMD+SHIFT+P** — close the game tab and re-open the menu.

(Don't use CMD+SHIFT+G — Kaku already binds it to lazygit.)

## Verify

- `luac -p ~/.config/kaku/kaku.lua` passes.
- `paws --list` shows at least one installed game.
- The hook paths in the agent config are absolute and the script is executable.

Report exactly which files you created or modified.
