return {
  -- 配置 LSP 服务器
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Python LSP
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic", -- off, basic, strict
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace", -- openFilesOnly, workspace
              },
            },
          },
        },

        -- C/C++ LSP
        clangd = {
          cmd = {
            "clangd", -- 使用默认 clangd（已链接到 clangd-18）
            "--background-index",
            "--clang-tidy",
            "--header-insertion=never", -- 内核代码不需要自动插入头文件
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
            "--query-driver=/usr/bin/aarch64-linux-gnu-gcc,/usr/bin/gcc", -- 让 clangd 理解交叉编译器
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = false, -- 内核代码关闭
            clangdFileStatus = true,
          },
        },
      },
    },
  },

  -- 配置 Mason 自动安装工具
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        -- LSP 服务器
        "pyright", -- Python LSP
        "clangd", -- C/C++ LSP

        -- 代码格式化工具
        "black", -- Python formatter
        "isort", -- Python import sorter
        "clang-format", -- C/C++ formatter

        -- 代码检查工具
        "ruff", -- Python linter (fast)
      },
    },
  },
}
