-- 禁用或修复 snacks dashboard 的错误
return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        enabled = false, -- 暂时禁用 dashboard 避免错误
      },
    },
  },
}
