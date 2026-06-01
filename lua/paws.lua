-- Paws 🐾 — native Kaku/WezTerm integration.
-- Add this to ~/.config/kaku/kaku.lua (before `return config`).
-- Everything runs in-process: no external scripts, no temp files, no `kaku cli`.
--
-- The game lives in its OWN TAB (full-window, never disturbs your panes).
--   CMD+G        : open the game tab (shows a centered menu) ↔ toggle back to agent
--   CMD+SHIFT+P  : close the game tab and re-open the menu
-- The picker, Random rotation and Settings all live inside the `paws` wrapper now,
-- so the menu is centered and styled. Manual switching only — no auto-jumping.
--
-- NOTE: CMD+SHIFT+G is intentionally NOT used — Kaku already binds it (lazygit).
-- Kaku does not auto-reload config; press CMD+Shift+R after editing.

local wezterm = require 'wezterm'

local PAWS_SHELL = os.getenv('SHELL') or '/bin/sh'  -- login shell, so PATH resolves

-- wezterm.mux.get_tab raises if the tab is gone; make it return nil instead
local function paws_tab(tab_id)
  if not tab_id then return nil end
  local ok, t = pcall(wezterm.mux.get_tab, tab_id)
  return ok and t or nil
end

-- spawn the game tab running the `paws` menu; remember the agent tab; activate it
local function paws_spawn(window, agent_tab_id)
  if agent_tab_id then wezterm.GLOBAL.paws_agent_tab = agent_tab_id end
  local tab = window:mux_window():spawn_tab { args = { PAWS_SHELL, '-l', '-c', 'paws' } }
  wezterm.GLOBAL.paws_game_tab = tab:tab_id()
  tab:activate()
end

config.keys = config.keys or {}
-- CMD+G: open the game tab (centered menu) / toggle agent ↔ game
table.insert(config.keys, {
  key = 'g',
  mods = 'CMD',
  action = wezterm.action_callback(function(window, pane)
    local game = paws_tab(wezterm.GLOBAL.paws_game_tab)
    if game then
      if pane:tab():tab_id() == wezterm.GLOBAL.paws_game_tab then
        local at = paws_tab(wezterm.GLOBAL.paws_agent_tab)
        if at then at:activate() end
      else
        game:activate()
      end
      return
    end
    paws_spawn(window, pane:tab():tab_id())
  end),
})
-- CMD+SHIFT+P: close any open game tab and re-open the menu
table.insert(config.keys, {
  key = 'P',
  mods = 'CMD|SHIFT',
  action = wezterm.action_callback(function(window, pane)
    local agent_id = wezterm.GLOBAL.paws_agent_tab or pane:tab():tab_id()
    local old = paws_tab(wezterm.GLOBAL.paws_game_tab)
    if old then
      old:activate()
      window:perform_action(wezterm.action.CloseCurrentTab { confirm = false }, old:active_pane())
    end
    paws_spawn(window, agent_id)
  end),
})
-- CMD+H: open the Paws repo (file an issue, say hi)
table.insert(config.keys, {
  key = 'h',
  mods = 'CMD',
  action = wezterm.action_callback(function()
    os.execute("open 'https://github.com/MisterBrookT/paws'")
  end),
})
