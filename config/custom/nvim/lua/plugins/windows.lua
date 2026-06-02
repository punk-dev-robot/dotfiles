return {
  "anuvyklack/windows.nvim",
  enabled = false,
  dependencies = {
    "anuvyklack/middleclass",
    "anuvyklack/animation.nvim",
  },
  config = function()
    -- comment out animation.nvim and below settings to disable animations
    vim.o.winwidth = 10
    vim.o.winminwidth = 10
    vim.o.equalalways = false
    require("windows").setup()
  end,
  keys = {
    { "<leader>wz", ":WindowsMaximize<CR>", desc = "Maximize Window" },
    { "<leader>w-", ":WindowsMaximizeVertically<CR>", desc = "Maximize Window Vertically" },
    { "<leader>w|", ":WindowsMaximizeHorizontally<CR>", desc = "Maximize Window Horizontally" },
    { "<leader>w=", ":WindowsEqualize<CR>", desc = "Equalize Windows" },
  },
}
