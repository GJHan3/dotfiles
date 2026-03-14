return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    -- 终端配置
    split_side = "right", -- Claude 终端在右侧
    split_width_percentage = 0.40, -- 占 40% 宽度（优化 tmux 环境显示）
    auto_start = true, -- 自动启动 WebSocket 服务器
    provider = "snacks", -- 使用 snacks 终端

    -- 工作目录配置
    git_repo_cwd = true, -- 自动定位到 git 仓库根目录

    -- Diff 配置
    auto_close_on_accept = true, -- 接受修改后自动关闭 diff
    vertical_split = true, -- 垂直分割显示 diff
    diff_split_direction = "left", -- diff 窗口在左侧

    -- Claude CLI 路径（使用 ept claude）
    terminal_cmd = "ept claude",

    -- 日志级别（调试时可以改成 "debug"）
    log_level = "info",
  },

  -- 快捷键配置
  keys = {
    -- 打开/关闭 Claude 终端
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },

    -- 聚焦到 Claude 终端
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude Code" },

    -- 发送选区到 Claude（visual 模式）
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send Selection to Claude" },

    -- 添加当前文件到 Claude 上下文
    { "<leader>aa", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add Current File to Claude" },

    -- Diff 操作
    { "<leader>aD", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude Changes" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny Claude Changes" },
  },

  -- 配置钩子：修复 diff 窗口布局，确保 Claude 在最右边
  config = function(_, opts)
    require("claudecode").setup(opts)

    -- 监听 diff 窗口，自动调整布局：确保 Claude 在最右边
    vim.api.nvim_create_autocmd("BufWinEnter", {
      pattern = "*",
      callback = function(args)
        -- 只在开启 diff 模式时处理
        if not vim.wo.diff then
          return
        end

        -- 延迟执行，等待所有 diff 窗口都创建完成
        vim.defer_fn(function()
          -- 收集所有窗口信息
          local diff_wins = {}
          local claude_win = nil

          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.bo[buf].filetype

            if vim.wo[win].diff then
              -- Diff 窗口
              table.insert(diff_wins, win)
            elseif ft == "snacks_terminal" then
              -- Claude 窗口
              claude_win = win
            end
          end

          -- 如果有 2 个 diff 窗口 且有 Claude 窗口
          if #diff_wins >= 2 and claude_win then
            -- 检查 Claude 是否在最右边（通过屏幕位置判断）
            local claude_is_rightmost = true
            local claude_pos = vim.fn.win_screenpos(claude_win)

            for _, diff_win in ipairs(diff_wins) do
              local diff_pos = vim.fn.win_screenpos(diff_win)
              -- 如果有 diff 窗口在 Claude 右边（列位置更大），说明布局错误
              if diff_pos[2] > claude_pos[2] then
                claude_is_rightmost = false
                break
              end
            end

            -- 如果 Claude 不在最右边，强制移动到最右边
            if not claude_is_rightmost then
              local current_win = vim.api.nvim_get_current_win()
              vim.api.nvim_set_current_win(claude_win)
              vim.cmd("wincmd L") -- 移动当前窗口到最右边
              -- 恢复焦点到原窗口
              if vim.api.nvim_win_is_valid(current_win) then
                vim.api.nvim_set_current_win(current_win)
              end
            end
          end
        end, 200) -- 延迟 200ms，确保所有窗口都创建完成
      end,
    })
  end,
}
