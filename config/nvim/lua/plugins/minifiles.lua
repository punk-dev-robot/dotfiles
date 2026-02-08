return {
  "nvim-mini/mini.files",
  enabled = false,
  opts = {
    windows = {
      width_preview = 75,
    },
    options = {
      use_as_default_explorer = false,
    },
  },
  keys = {
    {
      "<leader>e",
      function()
        require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
      end,
      desc = "Open mini.files (directory of current file)",
    },
    {
      "<leader>E",
      function()
        require("mini.files").open(vim.loop.cwd(), true)
      end,
      desc = "Open mini.files (cwd)",
    },
  },
}
