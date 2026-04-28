local external_file_change_group = vim.api.nvim_create_augroup("external_file_change", { clear = true })

local function check_external_file_changes()
  if vim.fn.mode():match("^[ciR]") then
    return
  end

  vim.cmd("silent! checktime")
end

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = external_file_change_group,
  callback = check_external_file_changes,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = external_file_change_group,
  callback = function()
    vim.fn.timer_start(1000, function()
      vim.schedule(check_external_file_changes)
    end, { ["repeat"] = -1 })
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

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    local current_buf = vim.api.nvim_get_current_buf()
    local current_name = vim.api.nvim_buf_get_name(current_buf)

    if current_name == "" then
      return
    end

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf ~= current_buf and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        local modified = vim.bo[buf].modified
        local buftype = vim.bo[buf].buftype

        if name == "" and not modified and buftype == "" then
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(buf) then
              pcall(vim.api.nvim_buf_delete, buf, { force = false })
            end
          end, 100)
        end
      end
    end
  end,
})
