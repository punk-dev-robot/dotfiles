return {
  {
    "sindrets/diffview.nvim",
    keys = {
      { "<leader>gdo", "<cmd>DiffviewOpen<CR>", desc = "Open diffview" },
      { "<leader>gdm", "<cmd>DiffviewOpen origin/master<CR>", desc = "Open diffview with master" },
      { "<leader>gdc", "<cmd>DiffviewClose<CR>", desc = "Close diffview" },
      { "<leader>gdr", "<cmd>DiffviewRefresh<CR>", desc = "Refresh diffview" },
      { "<leader>gdf", "<cmd>DiffviewToggleFiles<CR>", desc = "Toggle files sidebar" },
      { "<leader>gdh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
      { "<leader>gdH", "<cmd>DiffviewFileHistory<CR>", desc = "Branch history" },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>gd", group = "DiffView" },
      },
    },
  },
}
