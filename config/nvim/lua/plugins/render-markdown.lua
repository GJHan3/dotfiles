return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "gitcommit" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-mini/mini.icons",
    },
    keys = {
      {
        "<leader>mp",
        function()
          require("render-markdown").preview()
        end,
        desc = "Markdown Preview",
      },
      {
        "<leader>mt",
        function()
          require("render-markdown").buf_toggle()
        end,
        desc = "Toggle Markdown Render",
      },
    },
    ---@module "render-markdown"
    ---@type render.md.UserConfig
    opts = {
      enabled = true,
      file_types = { "markdown", "gitcommit" },
      render_modes = { "n", "c", "t" },
      heading = {
        sign = false,
        border = true,
        border_prefix = true,
        position = "overlay",
        icons = { "◈ ", "◆ ", "◉ ", "● ", "○ ", "□ " },
      },
      code = {
        border = "thin",
        left_pad = 1,
        right_pad = 1,
        language_pad = 1,
        style = "full",
      },
      bullet = {
        icons = { "•", "◦", "▪", "▫" },
        right_pad = 1,
      },
      checkbox = {
        left_pad = 0,
        right_pad = 1,
        unchecked = { icon = "☐ " },
        checked = { icon = "☑ " },
      },
      quote = {
        icon = "▋",
        repeat_linebreak = true,
      },
      pipe_table = {
        preset = "round",
        cell = "padded",
      },
      latex = {
        enabled = true,
      },
    },
  },
}
