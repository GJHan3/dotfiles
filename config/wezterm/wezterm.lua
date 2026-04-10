local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action
local nerdfonts = wezterm.nerdfonts

local function file_exists(path)
  local f = io.open(path, "rb")
  if f then
    f:close()
    return true
  end
  return false
end

local home = os.getenv("HOME") or ""
local background_candidates = {
  home .. "/dotfiles/config/wezterm/backgrounds/maplestory.png",
  home .. "/dotfiles/config/wezterm/backgrounds/maplestory.jpg",
  home .. "/dotfiles/config/wezterm/backgrounds/maplestory.jpeg",
  home .. "/dotfiles/config/wezterm/backgrounds/maplestory.webp",
  home .. "/Pictures/maplestory.png",
  home .. "/Pictures/maplestory.jpg",
  home .. "/Pictures/maplestory.jpeg",
  home .. "/Pictures/MapleStory.png",
  home .. "/Pictures/MapleStory.jpg",
  home .. "/Pictures/MapleStory.jpeg",
}

local background_image
for _, path in ipairs(background_candidates) do
  if file_exists(path) then
    background_image = path
    break
  end
end

-- Disable the default behavior that can translate mouse wheel events into
-- UpArrow/DownArrow in alternate screen contexts. Without this, scrolling can
-- show up in the shell as ^[[A/^[[B and trigger zsh history navigation instead
-- of scrolling terminal content.
config.alternate_buffer_wheel_scroll_speed = 0
config.font_size = 15.0
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32
config.window_decorations = "TITLE | RESIZE"

-- 开启全局透明透视：即使应用设置了背景色，也会带有透明度
config.text_background_opacity = 0.5
config.window_background_opacity = 0.95

-- Built-in scheme: Tokyo Night Moon.
config.color_scheme = "Tokyo Night Moon"
config.colors = {
  background = "#1e2030", -- 提亮背景基底颜色
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

-- config.window_background_opacity = 1.0
-- config.text_background_opacity = 1.0

if background_image then
  config.background = {
    {
      source = {
        File = background_image,
      },
      hsb = {
        brightness = 0.08,
      },
      opacity = 1.0,
      horizontal_align = "Center",
      vertical_align = "Middle",
      repeat_x = "NoRepeat",
      repeat_y = "NoRepeat",
    },
    {
      source = {
        Color = "#1e2030", -- 与背景色同步提亮
      },
      width = "100%",
      height = "100%",
      opacity = 0.65, -- 降低遮罩浓度，让背景图更亮
    },
  }
end

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
