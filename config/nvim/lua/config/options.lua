-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Force OSC 52 clipboard handling so SSH sessions avoid remote X11 clipboard tools.
local function paste()
  return {
    vim.fn.split(vim.fn.getreg('"'), "\n"),
    vim.fn.getregtype('"'),
  }
end

vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = paste,
    ["*"] = paste,
  },
}

-- Keep unnamedplus enabled, but route clipboard traffic through the OSC 52 provider above.
vim.opt.clipboard = "unnamedplus"

-- 设置窗口分隔符，使窗口边界更清晰
vim.opt.fillchars = {
  horiz = "━", -- 水平分隔线
  horizup = "┻", -- 水平向上连接
  horizdown = "┳", -- 水平向下连接
  vert = "┃", -- 垂直分隔线
  vertleft = "┫", -- 垂直向左连接
  vertright = "┣", -- 垂直向右连接
  verthoriz = "╋", -- 交叉连接
}

-- 使用绝对行号而不是相对行号
vim.opt.relativenumber = false
vim.opt.number = true

-- 长行默认按窗口宽度软换行，避免水平滚动阅读。
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true

-- Automatically reload files changed outside Neovim when the buffer has no local edits.
vim.opt.autoread = true

-- Give leader mappings a bit more time so Space-based key sequences are less easy to miss.
vim.opt.timeoutlen = 500
