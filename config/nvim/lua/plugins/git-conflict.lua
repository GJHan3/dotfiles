return {
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = "BufReadPost",
    opts = {
      default_mappings = false,
      default_commands = true,
      disable_diagnostics = false,
    },
    keys = {
      { "<leader>gco", "<cmd>GitConflictChooseOurs<cr>", desc = "Conflict: Choose Ours" },
      { "<leader>gct", "<cmd>GitConflictChooseTheirs<cr>", desc = "Conflict: Choose Theirs" },
      { "<leader>gcb", "<cmd>GitConflictChooseBoth<cr>", desc = "Conflict: Choose Both" },
      { "<leader>gc0", "<cmd>GitConflictChooseNone<cr>", desc = "Conflict: Choose None" },
      { "]x", "<cmd>GitConflictNextConflict<cr>", desc = "Next Git Conflict" },
      { "[x", "<cmd>GitConflictPrevConflict<cr>", desc = "Previous Git Conflict" },
    },
  },
}
