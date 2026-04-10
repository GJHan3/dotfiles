return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      heading = {
        sign = false,
        border = true,
        border_prefix = true,
        position = "overlay",
        icons = { " 󰲡  ", " 󰲣  ", " 󰲥  ", " 󰲧  ", " 󰲩  ", " 󰲫  " },
        backgrounds = {
          "RenderMarkdownH1Bg",
          "RenderMarkdownH2Bg",
          "RenderMarkdownH3Bg",
          "RenderMarkdownH4Bg",
          "RenderMarkdownH5Bg",
          "RenderMarkdownH6Bg",
        },
      },
      code = {
        border = "thin",
        left_pad = 1,
        right_pad = 1,
        language_pad = 1,
        style = "full",
        language_config = {
          mermaid = { sign = "󰚔 ", border = "thick" },
        },
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
    },
  },
}
