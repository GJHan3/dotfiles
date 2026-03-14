return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function(_, opts)
    -- 可爱风格的表情符号配置
    local icons = {
      git_branch = "✨",
      modified = "💖",
      readonly = "🔒",
      unnamed = "📝",
      newfile = "🌟",
      saved = "💾",
      error = "❌",
      warn = "⚠️",
      info = "💡",
      hint = "💭",
    }

    -- 常驻装饰表情（男性风格 - 科技/运动/军事混合）
    local decorative_emojis = {
      left = { "⚡", "🔥", "💥", "⚔️", "🛡️", "🎯", "🔫", "💣", "🎖️", "🏹" },    -- 力量/战斗/军事系列
      right = { "🚀", "🎮", "🏆", "👑", "💎", "🔱", "🤖", "💻", "⚙️", "🛸" },  -- 成就/科技系列
      center = { "💪", "🦾", "🤘", "👊", "✊", "🔧", "⚽", "🏀", "🏈", "⚾" },  -- 酷炫/运动系列
    }

    -- 随机选择表情的函数
    local function random_emoji(emoji_list)
      local index = math.random(1, #emoji_list)
      return emoji_list[index]
    end

    -- 常驻左侧装饰
    local function left_decoration()
      return random_emoji(decorative_emojis.left)
    end

    -- 常驻右侧装饰
    local function right_decoration()
      return random_emoji(decorative_emojis.right)
    end

    -- 常驻中间装饰
    local function center_decoration()
      return random_emoji(decorative_emojis.center)
    end

    -- 固定的可爱短语
    local cute_phrases = {
      "( ◕‿◕ )",
      "(｡♥‿♥｡)",
      "ヾ(◍°∇°◍)ﾉﾞ",
      "♪(๑ᴖ◡ᴖ๑)♪",
      "✧*。٩(ˊᗜˋ*)و✧*。",
    }

    local function random_phrase()
      local index = math.random(1, #cute_phrases)
      return cute_phrases[index]
    end

    -- 文件类型表情图标映射（更多类型）
    local filetype_icons = {
      python = "🐍",
      lua = "🌙",
      javascript = "💛",
      typescript = "💙",
      rust = "🦀",
      go = "🐹",
      c = "⚙️",
      cpp = "⚙️",
      java = "☕",
      ruby = "💎",
      php = "🐘",
      html = "🌐",
      css = "🎨",
      scss = "🎨",
      json = "📦",
      yaml = "📋",
      toml = "📋",
      markdown = "📖",
      text = "📝",
      vim = "💚",
      sh = "🐚",
      bash = "🐚",
      zsh = "🐚",
      fish = "🐠",
      docker = "🐳",
      sql = "🗄️",
      gitcommit = "💬",
      gitconfig = "⚙️",
      conf = "⚙️",
      default = "📄",
    }

    -- 模式表情图标
    local mode_icons = {
      n = "🎯",      -- NORMAL
      i = "✏️",      -- INSERT
      v = "👁️",      -- VISUAL
      V = "👁️",      -- V-LINE
      ["\22"] = "👁️", -- V-BLOCK
      c = "🎮",      -- COMMAND
      s = "📌",      -- SELECT
      S = "📌",      -- S-LINE
      ["\19"] = "📌", -- S-BLOCK
      R = "🔄",      -- REPLACE
      r = "🔄",
      ["!"] = "💥",  -- SHELL
      t = "💻",      -- TERMINAL
    }

    -- 自定义组件：模式 + 表情
    local function mode_with_icon()
      local mode = vim.api.nvim_get_mode().mode
      local icon = mode_icons[mode] or "🎯"
      return icon
    end

    -- 自定义组件：文件类型 + 表情
    local function filetype_with_icon()
      local ft = vim.bo.filetype
      local icon = filetype_icons[ft] or filetype_icons.default
      local display_ft = ft ~= "" and ft or "text"
      return icon .. " " .. display_ft
    end

    -- 自定义组件：Git 分支 + 表情
    local function branch_with_icon()
      local branch = vim.b.gitsigns_head or ""
      if branch ~= "" then
        return icons.git_branch .. " " .. branch
      end
      return ""
    end

    -- 自定义组件：文件状态 + 表情
    local function file_status()
      if vim.bo.modified then
        return icons.modified .. " Modified"
      elseif vim.bo.readonly then
        return icons.readonly .. " Readonly"
      else
        return "✓ Saved"
      end
    end

    -- 自定义组件：时间 + 表情
    local function time_with_icon()
      return "⏰ " .. os.date("%H:%M")
    end

    -- 自定义组件：日期 + 表情
    local function date_with_icon()
      return "📅 " .. os.date("%m/%d")
    end

    -- 自定义组件：LSP 状态 + 表情
    local function lsp_status()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      if #clients > 0 then
        local client_names = {}
        for _, client in ipairs(clients) do
          table.insert(client_names, client.name)
        end
        return "🌈 " .. table.concat(client_names, ",")
      end
      return ""
    end

    -- 自定义组件：诊断信息 + 表情
    local function diagnostics_with_icons()
      local result = {}
      local levels = {
        errors = { icon = icons.error, level = vim.diagnostic.severity.ERROR },
        warnings = { icon = icons.warn, level = vim.diagnostic.severity.WARN },
        info = { icon = icons.info, level = vim.diagnostic.severity.INFO },
        hints = { icon = icons.hint, level = vim.diagnostic.severity.HINT },
      }

      for name, config in pairs(levels) do
        local count = #vim.diagnostic.get(0, { severity = config.level })
        if count > 0 then
          table.insert(result, config.icon .. " " .. count)
        end
      end

      return table.concat(result, " ")
    end

    -- 自定义组件：文件大小 + 表情
    local function filesize_with_icon()
      local size = vim.fn.getfsize(vim.fn.expand("%:p"))
      if size <= 0 then
        return ""
      end

      local suffixes = { "B", "KB", "MB", "GB" }
      local i = 1
      while size > 1024 and i < #suffixes do
        size = size / 1024
        i = i + 1
      end

      return string.format("📊 %.1f%s", size, suffixes[i])
    end

    -- 自定义组件：编码 + 表情
    local function encoding_with_icon()
      local enc = vim.opt.fileencoding:get()
      if enc == "" then
        enc = vim.opt.encoding:get()
      end
      return "🔤 " .. enc:upper()
    end

    -- 自定义组件：文件格式 + 表情
    local function fileformat_with_icon()
      local format_icons = {
        unix = "🐧",
        dos = "🪟",
        mac = "🍎",
      }
      local format = vim.bo.fileformat
      return (format_icons[format] or "📝") .. " " .. format
    end

    -- 配置 lualine 各个部分
    opts.sections = {
      -- 左侧
      lualine_a = {
        { left_decoration },  -- 🌸 常驻装饰
        { mode_with_icon },
        { "mode" },
      },
      lualine_b = {
        branch_with_icon,
        {
          "diff",
          symbols = { added = "➕ ", modified = "✏️ ", removed = "➖ " },
        },
      },
      lualine_c = {
        {
          "filename",
          symbols = {
            modified = icons.modified,
            readonly = icons.readonly,
            unnamed = icons.unnamed,
            newfile = icons.newfile,
          },
        },
        { center_decoration },  -- 💖 常驻装饰
        filetype_with_icon,
        filesize_with_icon,
      },
      -- 右侧
      lualine_x = {
        diagnostics_with_icons,
        file_status,
        lsp_status,
      },
      lualine_y = {
        encoding_with_icon,
        fileformat_with_icon,
        "progress",
        "location",
      },
      lualine_z = {
        date_with_icon,
        time_with_icon,
        { right_decoration },  -- ✨ 常驻装饰
      },
    }

    return opts
  end,
}
