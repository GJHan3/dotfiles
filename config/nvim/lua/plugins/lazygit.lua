return {
  "kdheepak/lazygit.nvim",
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  -- optional for floating window border decoration
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  -- setting the keybinding for LazyGit with 'keys' is recommended in
  -- order to load the plugin when the command is run for the first time
  keys = {
    { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    { "<leader>gG", "<cmd>LazyGitCurrentFile<cr>", desc = "LazyGit (Current File)" },
    { "<leader>gl", "<cmd>terminal git log --oneline --graph --all -20<cr>", desc = "Git Log" },
    { "<leader>gr", "<cmd>terminal git reflog -20<cr>", desc = "Git Reflog" },
  },
}
