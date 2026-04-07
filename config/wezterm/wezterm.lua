local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Disable the default behavior that can translate mouse wheel events into
-- UpArrow/DownArrow in alternate screen contexts. Without this, scrolling can
-- show up in the shell as ^[[A/^[[B and trigger zsh history navigation instead
-- of scrolling terminal content.
config.alternate_buffer_wheel_scroll_speed = 0

return config
