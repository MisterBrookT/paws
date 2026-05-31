-- Paws: Kaku Lua config snippet
-- Add to ~/.config/kaku/kaku.lua
-- CMD+G = switch to game (full screen)

local wezterm = require 'wezterm'

wezterm.on('paws-switch-to-game', function(window, pane)
  local f = io.open('/tmp/paws-state.json', 'r')
  if not f then return end
  local content = f:read('*a')
  f:close()
  local game_pane_id = content:match('"game_pane_id":(%d+)')
  if game_pane_id then
    os.execute('kaku cli activate-pane --pane-id ' .. game_pane_id)
    os.execute('kaku cli zoom-pane --pane-id ' .. game_pane_id .. ' --zoom')
  end
end)

return {
  keys = {
    { key = 'g', mods = 'SUPER', action = wezterm.action.EmitEvent('paws-switch-to-game') },
  },
}
