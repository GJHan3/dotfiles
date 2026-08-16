local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action
local nerdfonts = wezterm.nerdfonts

local font_fallback = {
  { family = "JetBrains Mono", weight = "Medium" },
  "Symbols Nerd Font Mono",
}
if wezterm.target_triple:find("apple%-darwin") then
  table.insert(font_fallback, { family = "Hiragino Sans GB", weight = "Light" })
end

-- Disable the default behavior that can translate mouse wheel events into
-- UpArrow/DownArrow in alternate screen contexts. Without this, scrolling can
-- show up in the shell as ^[[A/^[[B and trigger zsh history navigation instead
-- of scrolling terminal content.
config.alternate_buffer_wheel_scroll_speed = 0
config.font = wezterm.font_with_fallback(font_fallback)
config.font_size = 15.0
config.line_height = 1.05
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32
config.window_decorations = "TITLE | RESIZE"

-- Keep the terminal background fully opaque so the configured color is stable.
config.text_background_opacity = 1.0
config.window_background_opacity = 1.0

-- Built-in scheme: Tokyo Night Moon.
config.color_scheme = "Tokyo Night Moon"
config.colors = {
  background = "#1e2030",
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
  tab_bar = {
    background = "#10151b",
    active_tab = {
      bg_color = "#a6557f",
      fg_color = "#f4f8ff",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "#243140",
      fg_color = "#9cb3c9",
    },
    inactive_tab_hover = {
      bg_color = "#2d4154",
      fg_color = "#d6dde8",
    },
    new_tab = {
      bg_color = "#10151b",
      fg_color = "#73daca",
    },
    new_tab_hover = {
      bg_color = "#17303b",
      fg_color = "#b8f2e6",
    },
  },
}

wezterm.on("format-tab-title", function(tab, tabs, panes, config_, hover, max_width)
  local title = tab.active_pane.title
  local index = tab.tab_index + 1
  local icon = tab.is_active and nerdfonts.md_star_four_points or nerdfonts.md_circle_small

  title = wezterm.truncate_right(title, max_width - 8)

  local bg = tab.is_active and "#a6557f" or hover and "#2d4154" or "#243140"
  local fg = tab.is_active and "#f4f8ff" or hover and "#e4edf8" or "#9cb3c9"
  local edge = tab.is_active and "#ff9ac1" or hover and "#6da6cf" or "#3d5368"
  local icon_fg = tab.is_active and "#ffd173" or hover and "#8ff0ff" or "#73daca"

  return {
    { Background = { Color = edge } },
    { Foreground = { Color = "#161b22" } },
    { Text = "▌" },
    { Background = { Color = bg } },
    { Foreground = { Color = icon_fg } },
    { Text = string.format(" %s ", icon) },
    { Foreground = { Color = fg } },
    { Text = string.format("%d:%s ", index, title) },
    { Background = { Color = edge } },
    { Foreground = { Color = "#161b22" } },
    { Text = "▐" },
  }
end)

config.keys = {
  {
    key = "PageUp",
    mods = "SHIFT",
    action = act.ScrollByPage(-1),
  },
  {
    key = "PageDown",
    mods = "SHIFT",
    action = act.ScrollByPage(1),
  },
  {
    key = "UpArrow",
    mods = "CMD",
    action = act.ScrollByLine(-3),
  },
  {
    key = "DownArrow",
    mods = "CMD",
    action = act.ScrollByLine(3),
  },
  {
    key = "x",
    mods = "CMD|SHIFT",
    action = act.ActivateCopyMode,
  },
  {
    key = "LeftArrow",
    mods = "CMD",
    action = act.SendKey { key = "b", mods = "ALT" },
  },
  {
    key = "RightArrow",
    mods = "CMD",
    action = act.SendKey { key = "f", mods = "ALT" },
  },
  {
    key = "Backspace",
    mods = "CMD",
    action = act.SendKey { key = "w", mods = "CTRL" },
  },
  -- Move tab left/right
  {
    key = "LeftArrow",
    mods = "CMD|SHIFT",
    action = act.MoveTabRelative(-1),
  },
  {
    key = "RightArrow",
    mods = "CMD|SHIFT",
    action = act.MoveTabRelative(1),
  },
  {
    key = "a",
    mods = "CMD",
    action = act.SendKey { key = "a", mods = "CTRL" },
  },
  {
    key = "e",
    mods = "CMD",
    action = act.SendKey { key = "e", mods = "CTRL" },
  },
}

return config
