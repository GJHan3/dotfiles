local english_input = "com.apple.keylayout.ABC"
local last_insert_input = english_input

local function has_im_select()
  return vim.fn.has("mac") == 1 and vim.fn.executable("im-select") == 1
end

local function current_input()
  if not has_im_select() then
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
  if not source or not has_im_select() then
    return
  end

  vim.fn.system({ "im-select", source })
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    set_input(english_input)
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
