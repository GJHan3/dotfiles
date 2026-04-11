-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function apply_ui_highlights()
  local transparent_groups = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "FloatBorder",
    "SignColumn",
    "EndOfBuffer",
    "FoldColumn",
    "LineNr",
    "CursorLineNr",
    "NeoTreeNormal",
    "NeoTreeNormalNC",
    "NeoTreeEndOfBuffer",
  }

  for _, group in ipairs(transparent_groups) do
    vim.api.nvim_set_hl(0, group, { bg = "NONE" })
  end

  -- 设置垂直分隔线的颜色为黄色
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#ffaa00", bg = "NONE" })
  -- 设置 winbar 的颜色 - 青色明亮
  vim.api.nvim_set_hl(0, "WinBar", { fg = "#00ffff", bg = "#1a2a2a", bold = true })
  -- 设置非当前窗口的 winbar 颜色 - 暗青色
  vim.api.nvim_set_hl(0, "WinBarNC", { fg = "#008888", bg = "#1a1a1a" })
  -- 设置可视模式选区为浅黄色
  vim.api.nvim_set_hl(0, "Visual", { fg = "#1f2937", bg = "#fef3c7" })
  vim.api.nvim_set_hl(0, "VisualNOS", { fg = "#1f2937", bg = "#fef3c7" })

  local git_signs = {
    GitSignsAdd = "#22c55e",
    GitSignsChange = "#60a5fa",
    GitSignsDelete = "#ef4444",
    GitSignsChangedelete = "#f97316",
    GitSignsTopdelete = "#ef4444",
    GitSignsUntracked = "#f59e0b",
    GitSignsStagedAdd = "#16a34a",
    GitSignsStagedChange = "#3b82f6",
    GitSignsStagedDelete = "#dc2626",
    GitSignsStagedChangedelete = "#ea580c",
    GitSignsStagedTopdelete = "#dc2626",
    GitSignsStagedUntracked = "#d97706",
  }

  for group, fg in pairs(git_signs) do
    vim.api.nvim_set_hl(0, group, { fg = fg, bg = "NONE" })
  end
end

local function force_english_input()
  if vim.fn.has("mac") ~= 1 or vim.fn.executable("im-select") ~= 1 then
    return
  end

  vim.fn.system({ "im-select", "com.apple.keylayout.ABC" })
end

local english_input = "com.apple.keylayout.ABC"
local last_insert_input = english_input

local function current_input()
  if vim.fn.has("mac") ~= 1 or vim.fn.executable("im-select") ~= 1 then
    return nil
  end

  local result = vim.fn.system({ "im-select" })
  if vim.v.shell_error ~= 0 then
    return nil
  end

  result = vim.trim(result)
  return result ~= "" and result or nil
end

local function set_input(source)
  if not source or vim.fn.has("mac") ~= 1 or vim.fn.executable("im-select") ~= 1 then
    return
  end

  vim.fn.system({ "im-select", source })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = apply_ui_highlights,
})

vim.api.nvim_create_autocmd("User", {
  pattern = { "VeryLazy", "TransparentClear" },
  callback = apply_ui_highlights,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    apply_ui_highlights()
    force_english_input()
    last_insert_input = current_input() or english_input
  end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    set_input(last_insert_input)
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    last_insert_input = current_input() or last_insert_input
    set_input(english_input)
  end,
})

local external_file_change_group = vim.api.nvim_create_augroup("external_file_change", { clear = true })

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = external_file_change_group,
  callback = function()
    if vim.fn.mode():match("^[ciR]") then
      return
    end

    vim.cmd("silent! checktime")
  end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = external_file_change_group,
  callback = function(event)
    local name = vim.api.nvim_buf_get_name(event.buf)
    local label = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "buffer"
    vim.notify("Reloaded external changes: " .. label, vim.log.levels.INFO)
  end,
})

-- 立即应用当前配色方案的设置
apply_ui_highlights()

local function is_git_terminal_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "terminal" then
    return false
  end

  local name = vim.api.nvim_buf_get_name(buf)
  return name:match("term://.*lazygit") ~= nil
    or name:match("term://.*git log") ~= nil
    or name:match("term://.*git reflog") ~= nil
end

local function close_buffer_windows(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end

local function close_special_buffer(buf)
  close_buffer_windows(buf)

  if vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

local function set_close_keymaps(buf, desc)
  local close = function()
    close_special_buffer(buf)
  end

  vim.keymap.set("n", "q", close, { buffer = buf, desc = desc or "Close Window" })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, desc = desc or "Close Window" })
end

-- 设置 winbar 显示文件名
vim.opt.winbar = "%{%v:lua.require'utils.winbar'.winbar()%}"

-- 自动关闭空的 [No Name] buffer
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    -- 获取当前 buffer
    local current_buf = vim.api.nvim_get_current_buf()
    local current_name = vim.api.nvim_buf_get_name(current_buf)

    -- 只在打开有名字的文件时触发
    if current_name ~= "" then
      -- 查找所有空的 [No Name] buffer
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= current_buf and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
          local name = vim.api.nvim_buf_get_name(buf)
          local modified = vim.bo[buf].modified
          local buftype = vim.bo[buf].buftype

          -- 如果是空名字、未修改、非特殊类型的 buffer
          if name == "" and not modified and buftype == "" then
            -- 延迟删除，避免影响当前操作
            vim.defer_fn(function()
              if vim.api.nvim_buf_is_valid(buf) then
                pcall(vim.api.nvim_buf_delete, buf, { force = false })
              end
            end, 100)
          end
        end
      end
    end
  end,
})

-- 在 Trouble 窗口中设置智能跳转
vim.api.nvim_create_autocmd("FileType", {
  pattern = "trouble",
  callback = function(event)
    set_close_keymaps(event.buf, "Close Trouble")

    vim.keymap.set("n", "<cr>", function()
      -- 保存当前 trouble 窗口
      local trouble_win = vim.api.nvim_get_current_win()

      -- 查找最近使用的编辑窗口
      local special_fts = { "trouble", "neo-tree", "qf", "help", "terminal" }
      local target_win = nil

      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win ~= trouble_win then
          local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
          if ok then
            local ft = vim.bo[buf].filetype or ""
            local bt = vim.bo[buf].buftype or ""

            if not vim.tbl_contains(special_fts, ft) and bt == "" then
              target_win = win
              break
            end
          end
        end
      end

      -- 切换到目标窗口
      if target_win then
        vim.api.nvim_set_current_win(target_win)
      end

      -- 执行 Trouble 的跳转
      require("trouble").jump()
    end, { buffer = event.buf, desc = "Jump to item in last used window" })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "help", "qf", "man", "lspinfo", "notify" },
  callback = function(event)
    set_close_keymaps(event.buf)
  end,
})

vim.api.nvim_create_autocmd({ "BufWinEnter", "TermOpen" }, {
  pattern = "*",
  callback = function(event)
    local buf = event.buf
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    local name = vim.api.nvim_buf_get_name(buf)
    if name:match("^gitsigns://") then
      set_close_keymaps(buf, "Close Git History")
    end
  end,
})

-- 让 Git 终端在进程退出后自动关闭窗口，避免退出程序后还要再手动关一次。
vim.api.nvim_create_autocmd("TermClose", {
  pattern = "*",
  callback = function(event)
    local buf = event.buf
    if not is_git_terminal_buffer(buf) then
      return
    end

    vim.schedule(function()
      close_special_buffer(buf)
    end)
  end,
})
