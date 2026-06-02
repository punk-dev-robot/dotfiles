return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "marilari88/neotest-vitest",
      "haydenmeade/neotest-jest",
    },
    opts = {
      adapters = {
        ["neotest-vitest"] = {
          cwd = function()
            return LazyVim.root()
          end,
        },
        ["neotest-jest"] = {
          jestCommand = "npx jest",
          cwd = function()
            return LazyVim.root()
          end,
        },
      },
    },
  },
}
