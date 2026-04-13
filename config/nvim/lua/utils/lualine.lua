local M = {}

local icons = {
  git_branch = "✨",
  modified = "💖",
  readonly = "🔒",
  unnamed = "📝",
  newfile = "🌟",
  error = "❌",
  warn = "⚠️",
  info = "💡",
  hint = "💭",
}

local decorative_emojis = {
  left = { "⚡", "🔥", "💥", "⚔️", "🛡️", "🎯", "🔫", "💣", "🎖️", "🏹" },
  right = { "🚀", "🎮", "🏆", "👑", "💎", "🔱", "🤖", "💻", "⚙️", "🛸" },
  center = { "💪", "🦾", "🤘", "👊", "✊", "🔧", "⚽", "🏀", "🏈", "⚾" },
}

local filetype_icons = {
  python = "🐍",
  lua = "🌙",
  javascript = "💛",
  typescript = "💙",
  rust = "🦀",
  go = "🐹",
  c = "⚙️",
  cpp = "⚙️",
  java = "☕",
  ruby = "💎",
  php = "🐘",
  html = "🌐",
  css = "🎨",
  scss = "🎨",
  json = "📦",
  yaml = "📋",
  toml = "📋",
  markdown = "📖",
  text = "📝",
  vim = "💚",
  sh = "🐚",
  bash = "🐚",
  zsh = "🐚",
  fish = "🐠",
  docker = "🐳",
  sql = "🗄️",
  gitcommit = "💬",
  gitconfig = "⚙️",
  conf = "⚙️",
  default = "📄",
}

local mode_icons = {
  n = "🎯",
  i = "✏️",
  v = "👁️",
  V = "👁️",
  ["\22"] = "👁️",
  c = "🎮",
  s = "📌",
  S = "📌",
  ["\19"] = "📌",
  R = "🔄",
  r = "🔄",
  ["!"] = "💥",
  t = "💻",
}

local decorations = {
  left = decorative_emojis.left[math.random(1, #decorative_emojis.left)],
  center = decorative_emojis.center[math.random(1, #decorative_emojis.center)],
  right = decorative_emojis.right[math.random(1, #decorative_emojis.right)],
}

local function left_decoration()
  return decorations.left
end

local function center_decoration()
  return decorations.center
end

local function right_decoration()
  return decorations.right
end

local function mode_with_icon()
  local mode = vim.api.nvim_get_mode().mode
  return mode_icons[mode] or mode_icons.n
end

local function filetype_with_icon()
  local ft = vim.bo.filetype
  local icon = filetype_icons[ft] or filetype_icons.default
  local display_ft = ft ~= "" and ft or "text"
  return icon .. " " .. display_ft
end

local function branch_with_icon()
  local branch = vim.b.gitsigns_head or ""
  return branch ~= "" and icons.git_branch .. " " .. branch or ""
end

local function file_status()
  if vim.bo.modified then
    return icons.modified .. " Modified"
  elseif vim.bo.readonly then
    return icons.readonly .. " Readonly"
  end

  return "✓ Saved"
end

local function time_with_icon()
  return "⏰ " .. os.date("%H:%M")
end

local function date_with_icon()
  return "📅 " .. os.date("%m/%d")
end

local function lsp_status()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ""
  end

  local client_names = {}
  for _, client in ipairs(clients) do
    table.insert(client_names, client.name)
  end

  return "🌈 " .. table.concat(client_names, ",")
end

local function diagnostics_with_icons()
  local result = {}
  local levels = {
    errors = { icon = icons.error, level = vim.diagnostic.severity.ERROR },
    warnings = { icon = icons.warn, level = vim.diagnostic.severity.WARN },
    info = { icon = icons.info, level = vim.diagnostic.severity.INFO },
    hints = { icon = icons.hint, level = vim.diagnostic.severity.HINT },
  }

  for _, config in pairs(levels) do
    local count = #vim.diagnostic.get(0, { severity = config.level })
    if count > 0 then
      table.insert(result, config.icon .. " " .. count)
    end
  end

  return table.concat(result, " ")
end

local function filesize_with_icon()
  local size = vim.fn.getfsize(vim.fn.expand("%:p"))
  if size <= 0 then
    return ""
  end

  local suffixes = { "B", "KB", "MB", "GB" }
  local i = 1
  while size > 1024 and i < #suffixes do
    size = size / 1024
    i = i + 1
  end

  return string.format("📊 %.1f%s", size, suffixes[i])
end

local function encoding_with_icon()
  local enc = vim.opt.fileencoding:get()
  if enc == "" then
    enc = vim.opt.encoding:get()
  end

  return "🔤 " .. enc:upper()
end

local function fileformat_with_icon()
  local format_icons = {
    unix = "🐧",
    dos = "🪟",
    mac = "🍎",
  }

  local format = vim.bo.fileformat
  return (format_icons[format] or "📝") .. " " .. format
end

function M.sections()
  return {
    lualine_a = {
      { left_decoration },
      { mode_with_icon },
      { "mode" },
    },
    lualine_b = {
      branch_with_icon,
      {
        "diff",
        symbols = { added = "➕ ", modified = "✏️ ", removed = "➖ " },
      },
    },
    lualine_c = {
      {
        "filename",
        symbols = {
          modified = icons.modified,
          readonly = icons.readonly,
          unnamed = icons.unnamed,
          newfile = icons.newfile,
        },
      },
      { center_decoration },
      filetype_with_icon,
      filesize_with_icon,
    },
    lualine_x = {
      diagnostics_with_icons,
      file_status,
      lsp_status,
    },
    lualine_y = {
      encoding_with_icon,
      fileformat_with_icon,
      "progress",
      "location",
    },
    lualine_z = {
      date_with_icon,
      time_with_icon,
      { right_decoration },
    },
  }
end

return M
