-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Git diff 对比
vim.keymap.set("n", "<leader>gd", function()
  require("gitsigns").diffthis()
end, { desc = "Git Diff" })

-- 关闭 diff
vim.keymap.set("n", "<leader>gq", function()
  -- 先关闭 diff 模式
  vim.cmd("diffoff!")

  -- 关闭 gitsigns 创建的历史版本窗口
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local bufname = vim.api.nvim_buf_get_name(buf)
    local buftype = vim.bo[buf].buftype

    -- gitsigns 创建的窗口特征：bufname 包含 "gitsigns://" 或 buftype 为 "nofile"
    if bufname:match("gitsigns://") or (buftype == "nofile" and bufname:match("^/")) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end, { desc = "Close Diff" })

-- 快速聚焦到搜索结果窗口（Trouble/Quickfix/Telescope）
vim.keymap.set("n", "<leader>xf", function()
  -- 优先查找 Trouble 窗口
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local filetype = vim.bo[buf].filetype
    local buftype = vim.bo[buf].buftype

    -- 查找 Trouble、Quickfix、Telescope 等搜索结果窗口
    if filetype == "trouble" or
       filetype == "qf" or
       buftype == "quickfix" or
       filetype == "TelescopePrompt" then
      vim.api.nvim_set_current_win(win)
      return
    end
  end

  -- 如果没有打开的搜索窗口，尝试打开 Trouble
  vim.notify("No search result window found", vim.log.levels.WARN)
end, { desc = "Focus Search Result Window" })

-- 智能窗口分割：避免在特殊窗口（Trouble、NeoTree 等）中分割
local function smart_split(split_cmd)
  return function()
    local filetype = vim.bo.filetype
    local special_filetypes = { "trouble", "neo-tree", "qf", "help", "terminal" }

    -- 如果在特殊窗口，先跳转到主编辑窗口
    if vim.tbl_contains(special_filetypes, filetype) then
      -- 查找第一个普通编辑窗口
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.bo[buf].filetype
        if not vim.tbl_contains(special_filetypes, ft) and vim.bo[buf].buftype == "" then
          vim.api.nvim_set_current_win(win)
          break
        end
      end
    end
    -- 执行分割命令
    vim.cmd(split_cmd)
  end
end

-- 覆盖默认的分割命令
vim.keymap.set("n", "<C-w>v", smart_split("vsplit"), { desc = "Smart Vertical Split" })
vim.keymap.set("n", "<C-w>s", smart_split("split"), { desc = "Smart Horizontal Split" })

-- 窗口大小调整快捷键
vim.keymap.set("n", "<leader>w+", "<cmd>vertical resize +10<cr>", { desc = "Increase window width" })
vim.keymap.set("n", "<leader>w-", "<cmd>vertical resize -10<cr>", { desc = "Decrease window width" })
vim.keymap.set("n", "<leader>w>", "<cmd>vertical resize +5<cr>", { desc = "Increase window width (small)" })
vim.keymap.set("n", "<leader>w<", "<cmd>vertical resize -5<cr>", { desc = "Decrease window width (small)" })
vim.keymap.set("n", "<leader>wh", "<cmd>resize +5<cr>", { desc = "Increase window height" })
vim.keymap.set("n", "<leader>wl", "<cmd>resize -5<cr>", { desc = "Decrease window height" })
vim.keymap.set("n", "<leader>w=", "<C-w>=", { desc = "Balance window sizes" })
vim.keymap.set("n", "<leader>wm", "<C-w>|<C-w>_", { desc = "Maximize current window" })

-- 终端模式配置
-- 使用 ESC 退出终端模式到普通模式
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- 在终端普通模式下按 q 关闭终端窗口
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    local opts = { buffer = 0 }
    -- 在终端的普通模式下，按 q 关闭窗口
    vim.keymap.set("n", "q", "<cmd>close<cr>", vim.tbl_extend("force", opts, { desc = "Close terminal window" }))
    -- 按 i 或 a 重新进入插入模式
    vim.keymap.set("n", "i", "i", vim.tbl_extend("force", opts, { desc = "Enter insert mode" }))
    vim.keymap.set("n", "a", "a", vim.tbl_extend("force", opts, { desc = "Enter insert mode" }))
  end,
})

