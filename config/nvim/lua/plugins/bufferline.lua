return {
  {
    "akinsho/bufferline.nvim",
    keys = {
      { "gb", "<cmd>BufferLinePick<cr>", desc = "Pick Buffer" },
      { "gB", "<cmd>BufferLinePickClose<cr>", desc = "Pick and Close Buffer" },
    },
    opts = {
      options = {
        pick = {
          alphabet = "abcdefghijklmopqrstuvwxyz",
        },
      },
    },
  },
}
