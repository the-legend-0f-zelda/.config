local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font('Cascadia Code')
config.font_size = 13.0
config.color_scheme = 'Tokyo Night'

config.window_background_opacity = 0.8
config.enable_tab_bar = false
config.window_decorations = 'RESIZE'

config.default_prog = { 'C:/Program Files/nu/bin/nu.exe' }

-- Nushell 렌더링 밀림 방지
config.allow_win32_input_mode = false

return config
