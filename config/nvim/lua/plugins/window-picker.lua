return {
  -- nvim-window-picker: 快速窗口跳转
  {
    "s1n7ax/nvim-window-picker",
    name = "window-picker",
    lazy = false, -- 立即加载
    version = "2.*",
    config = function()
      require("window-picker").setup({
        hint = "floating-big-letter", -- 显示大字母提示
        show_prompt = true,
        prompt_message = "Pick a window: ",
        filter_rules = {
          -- 过滤特殊窗口
          autoselect_one = true, -- 只有一个窗口时自动选择
          include_current_win = false, -- 排除当前窗口
          bo = {
            -- 排除这些 buffer 类型的窗口
            filetype = { "neo-tree", "neo-tree-popup", "notify", "noice", "trouble" },
            buftype = { "quickfix" }, -- 移除 terminal，允许选择 Claude 终端
          },
        },
        -- 高亮配置
        highlights = {
          statusline = {
            focused = {
              fg = "#ededed",
              bg = "#e35e4f",
              bold = true,
            },
            unfocused = {
              fg = "#ededed",
              bg = "#44cc41",
              bold = true,
            },
          },
          winbar = {
            focused = {
              fg = "#ededed",
              bg = "#e35e4f",
              bold = true,
            },
            unfocused = {
              fg = "#ededed",
              bg = "#44cc41",
              bold = true,
            },
          },
        },
      })

      -- 直接设置全局快捷键
      vim.keymap.set("n", "gw", function()
        local window_number = require("window-picker").pick_window()
        if window_number then
          vim.api.nvim_set_current_win(window_number)
        end
      end, { desc = "Pick Window" })
    end,
  },

  -- 或者使用内置的更轻量级方案（备选）
  {
    "folke/flash.nvim",
    opts = function(_, opts)
      opts.modes = opts.modes or {}
      opts.modes.char = opts.modes.char or {}
      -- 启用 f/F/t/T 增强
      opts.modes.char.enabled = true
    end,
    keys = {
      -- 使用 flash 跳转窗口（备选方案）
      {
        "gW",
        function()
          require("flash").jump({
            search = { mode = "search", max_length = 0 },
            label = { after = { 0, 0 } },
            pattern = "^",
            action = function(match, state)
              state:hide()
              vim.api.nvim_set_current_win(match.win)
            end,
          })
        end,
        desc = "Flash Window Jump",
      },
    },
  },
}
