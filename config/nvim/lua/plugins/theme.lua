return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      on_highlights = function(highlights)
        highlights.Visual = { fg = "#1f2937", bg = "#fef3c7" }
        highlights.VisualNOS = { fg = "#1f2937", bg = "#fef3c7" }
      end,
    },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      transparent_background = true,
      custom_highlights = function()
        return {
          Visual = { fg = "#1f2937", bg = "#fef3c7" },
          VisualNOS = { fg = "#1f2937", bg = "#fef3c7" },
        }
      end,
      integrations = {
        render_markdown = true,
      },
    },
  },
}
