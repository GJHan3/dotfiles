local M = {}

function M.apply_highlights()
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

  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#ffaa00", bg = "NONE" })
  vim.api.nvim_set_hl(0, "WinBar", { fg = "#00ffff", bg = "#1a2a2a", bold = true })
  vim.api.nvim_set_hl(0, "WinBarNC", { fg = "#008888", bg = "#1a1a1a" })
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

vim.opt.winbar = "%{%v:lua.require'utils.winbar'.winbar()%}"

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = M.apply_highlights,
})

vim.api.nvim_create_autocmd("User", {
  pattern = { "VeryLazy", "TransparentClear" },
  callback = M.apply_highlights,
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = M.apply_highlights,
})

M.apply_highlights()

return M
