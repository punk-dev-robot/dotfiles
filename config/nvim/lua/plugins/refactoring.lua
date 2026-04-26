return {
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "lewis6991/async.nvim",
    },
    config = function(_, opts)
      require("refactoring").setup(opts)
    end,
  },
}
