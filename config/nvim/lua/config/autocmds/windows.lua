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

vim.api.nvim_create_autocmd("FileType", {
  pattern = "trouble",
  callback = function(event)
    set_close_keymaps(event.buf, "Close Trouble")

    vim.keymap.set("n", "<cr>", function()
      local trouble_win = vim.api.nvim_get_current_win()
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

      if target_win then
        vim.api.nvim_set_current_win(target_win)
      end

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

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function(event)
    local opts = { buffer = event.buf }
    vim.keymap.set("n", "q", "<cmd>close<cr>", vim.tbl_extend("force", opts, { desc = "Close terminal window" }))
    vim.keymap.set("n", "i", "i", vim.tbl_extend("force", opts, { desc = "Enter insert mode" }))
    vim.keymap.set("n", "a", "a", vim.tbl_extend("force", opts, { desc = "Enter insert mode" }))
  end,
})

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
