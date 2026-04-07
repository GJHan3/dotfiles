local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Disable the default behavior that can translate mouse wheel events into
-- UpArrow/DownArrow in alternate screen contexts. Without this, scrolling can
-- show up in the shell as ^[[A/^[[B and trigger zsh history navigation instead
-- of scrolling terminal content.
config.alternate_buffer_wheel_scroll_speed = 0

-- Built-in scheme: Tokyo Night Moon. It keeps the blue/cyan "tech" feel, but
-- is softer than very deep black themes. The manual color overrides below lift
-- the background a bit further and increase ANSI contrast so syntax keywords,
-- prompts, and status colors remain easy to distinguish.
config.color_scheme = "Tokyo Night Moon"
config.colors = {
  background = "#20242a",
  foreground = "#d6dde8",
  cursor_bg = "#8bd49c",
  cursor_border = "#8bd49c",
  cursor_fg = "#20242a",
  selection_bg = "#32435f",
  selection_fg = "#eaf2ff",

  ansi = {
    "#2d3139",
    "#ff7a93",
    "#8bd49c",
    "#ffd173",
    "#7aa2f7",
    "#c099ff",
    "#73daca",
    "#d8e2f1",
  },
  brights = {
    "#5a616d",
    "#ff9db0",
    "#a6e3b9",
    "#ffe199",
    "#9bbcff",
    "#d2b2ff",
    "#93e6db",
    "#f4f8ff",
  },
}

return config
