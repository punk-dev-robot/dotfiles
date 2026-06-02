return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
  {
    "folke/tokyonight.nvim",
    enabled = false,
  },
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    enabled = not vim.g.started_by_firenvim,
  },
}
