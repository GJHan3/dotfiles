-- 简单的 winbar 实现（备选方案）
local M = {}

function M.winbar()
  -- 获取当前 buffer 的文件类型
  local filetype = vim.bo.filetype

  -- 排除特殊窗口
  local excluded_filetypes = {
    "neo-tree",
    "trouble",
    "qf",
    "help",
    "terminal",
    "lazy",
    "mason",
    "snacks_dashboard",
    "snacks_notif",
    "snacks_terminal",
    "snacks_win",
  }

  -- 也排除包含 "snacks" 的 filetype
  if filetype:match("snacks") then
    return ""
  end

  if vim.tbl_contains(excluded_filetypes, filetype) then
    return ""
  end

  -- 获取文件名和路径
  local filename = vim.fn.expand("%:t")
  local filepath = vim.fn.expand("%:~:.:h")

  -- 如果没有文件名，不显示 winbar
  if filename == "" then
    return ""
  end

  -- 检查是否修改
  local modified = vim.bo.modified and " ●" or ""

  -- 构建显示字符串
  if filepath == "." or filepath == "" then
    -- 只显示文件名（当前目录）
    return string.format(" %s%s ", filename, modified)
  else
    -- 显示路径 + 文件名
    return string.format(" %s/%s%s ", filepath, filename, modified)
  end
end

return M
