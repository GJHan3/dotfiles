return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = {}, -- 禁用 markdown 的所有 linter（主要是 markdownlint）
      },
    },
  },
}
