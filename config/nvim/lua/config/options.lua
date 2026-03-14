-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Force use of OSC 52 for clipboard (SSH remote support)
-- This allows copying to system clipboard from inside nvim over SSH
local function paste()
  return {
    vim.fn.split(vim.fn.getreg('"'), "\n"),
    vim.fn.getregtype('"'),
  }
end

vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = paste,
    ['*'] = paste,
  },
}

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See :help 'clipboard'
vim.opt.clipboard = "unnamedplus"

-- 设置窗口分隔符，使窗口边界更清晰
vim.opt.fillchars = {
  horiz = "━",     -- 水平分隔线
  horizup = "┻",   -- 水平向上连接
  horizdown = "┳", -- 水平向下连接
  vert = "┃",      -- 垂直分隔线
  vertleft = "┫",  -- 垂直向左连接
  vertright = "┣", -- 垂直向右连接
  verthoriz = "╋", -- 交叉连接
}

-- 使用绝对行号而不是相对行号
vim.opt.relativenumber = false
vim.opt.number = true