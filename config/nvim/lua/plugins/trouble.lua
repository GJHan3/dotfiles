return {
  {
    "folke/trouble.nvim",
    opts = {
      focus = true, -- 打开时自动聚焦
      follow = false, -- 禁用自动跟随
      modes = {
        qflist = {
          follow = false,
          auto_open = false,
          auto_close = false,
          auto_preview = false,
          win = {
            position = "bottom",
            size = 0.3,
          },
        },
      },
    },
  },
}
