return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "marilari88/neotest-vitest",
    },
    opts = {
      adapters = {
        ["neotest-vitest"] = {
          cwd = function()
            return LazyVim.root()
          end,
        },
      },
    },
  },
}
