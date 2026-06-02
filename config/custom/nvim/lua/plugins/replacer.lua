return {
  "gabrielpoca/replacer.nvim",
  enabled = false,
  ft = "qf",
  opts = {
    -- save_on_write = false,
    -- rename_files = false,
  },
  keys = {
    {
      "<leader>xr",
      function()
        require("replacer").run()
      end,
      desc = "Replace in quickfix (replacer)",
    },
  },
}
