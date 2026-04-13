return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function(_, opts)
    opts.sections = require("utils.lualine").sections()
    return opts
  end,
}
