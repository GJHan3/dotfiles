return {
  "rmagatti/goto-preview",
  event = "LspAttach",
  config = function()
    require("goto-preview").setup({
      width = 120, -- 预览窗口宽度
      height = 15, -- 预览窗口高度
      border = { "↖", "─", "╮", "│", "╯", "─", "╰", "│" }, -- 边框样式
      default_mappings = false, -- 禁用默认快捷键
      focus_on_open = true, -- 打开时聚焦到预览窗口
      dismiss_on_move = false, -- 移动光标时不关闭
      force_close = true, -- 强制关闭其他预览窗口
      bufhidden = "wipe", -- 关闭时清理 buffer
      post_open_hook = function(buf, win)
        -- 在预览窗口中设置 q 关闭快捷键
        vim.keymap.set("n", "q", function()
          require("goto-preview").close_all_win()
        end, { buffer = buf, desc = "Close Preview" })

        -- ESC 也可以关闭
        vim.keymap.set("n", "<ESC>", function()
          require("goto-preview").close_all_win()
        end, { buffer = buf, desc = "Close Preview" })
      end,
    })
  end,
  keys = {
    -- 预览定义
    {
      "gpd",
      function()
        require("goto-preview").goto_preview_definition()
      end,
      desc = "Preview Definition",
    },

    -- 预览类型定义
    {
      "gpt",
      function()
        require("goto-preview").goto_preview_type_definition()
      end,
      desc = "Preview Type Definition",
    },

    -- 预览实现
    {
      "gpi",
      function()
        require("goto-preview").goto_preview_implementation()
      end,
      desc = "Preview Implementation",
    },

    -- 预览引用
    {
      "gpr",
      function()
        require("goto-preview").goto_preview_references()
      end,
      desc = "Preview References",
    },

    -- 关闭所有预览窗口
    {
      "gpc",
      function()
        require("goto-preview").close_all_win()
      end,
      desc = "Close All Previews",
    },
  },
}
