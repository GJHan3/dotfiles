return {
  -- 添加 telescope-live-grep-args 依赖
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    version = "^1.0.0",
    config = function()
      require("telescope").load_extension("live_grep_args")
    end,
  },

  -- 扩展 telescope 配置
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-live-grep-args.nvim",
    },
    opts = function(_, opts)
      local actions = require("telescope.actions")
      local lga_actions = require("telescope-live-grep-args.actions")

      -- 自定义 action：发送到 quickfix 然后打开 Trouble 并聚焦
      local function send_to_trouble(prompt_bufnr)
        actions.send_to_qflist(prompt_bufnr)
        vim.schedule(function()
          -- 先关闭可能存在的 qflist，确保重新打开
          vim.cmd("Trouble qflist close")
          vim.defer_fn(function()
            vim.cmd("Trouble qflist open focus=true")
          end, 50)
        end)
      end

      -- 合并到默认 mappings（与 LazyVim 的方式一致）
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        -- 配置边框样式
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        -- 显示结果数量和搜索状态
        dynamic_preview_title = true,
        -- 在结果窗口底部显示状态信息
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
          },
        },
        -- 排序策略：从上到下
        sorting_strategy = "ascending",
        -- 自定义状态文本，添加加载动画
        get_status_text = function(self, opts)
          local multi_select_cnt = #(self:get_multi_selection())
          local showing_cnt = (self.stats.processed or 0) - (self.stats.filtered or 0)
          local total_cnt = self.stats.processed or 0

          local status_text = ""

          if opts and not opts.completed then
            -- 正在搜索：显示 spinner + "Searching..."
            local spinner = Snacks.util.spinner()
            status_text = string.format("%s Searching... [%d / %d]", spinner, showing_cnt, total_cnt)
          else
            -- 搜索完成：显示 "Results"
            status_text = string.format("Results [%d / %d]", showing_cnt, total_cnt)
          end

          -- 如果有多选，附加多选数量
          if multi_select_cnt > 0 then
            status_text = status_text .. string.format(" (%d)", multi_select_cnt)
          end

          return status_text
        end,
        mappings = {
          i = {
            ["<C-q>"] = send_to_trouble,
          },
          n = {
            ["<C-q>"] = send_to_trouble,
          },
        },
      })

      -- 配置 live_grep_args 扩展
      opts.extensions = vim.tbl_deep_extend("force", opts.extensions or {}, {
        live_grep_args = {
          auto_quoting = true,
          mappings = {
            i = {
              ["<C-k>"] = lga_actions.quote_prompt(),
              ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
            },
          },
        },
      })

      return opts
    end,
    keys = {
      -- 覆盖默认的 <leader>sg，使用 live_grep_args
      {
        "<leader>sg",
        function()
          require("telescope").extensions.live_grep_args.live_grep_args()
        end,
        desc = "Grep with Args (Root Dir)",
      },
      -- 添加 cwd 版本
      {
        "<leader>sG",
        function()
          require("telescope").extensions.live_grep_args.live_grep_args({ cwd = vim.uv.cwd() })
        end,
        desc = "Grep with Args (cwd)",
      },
    },
  },
}
