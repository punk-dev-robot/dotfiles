-- return {}
return {
  "folke/noice.nvim",
  opts = function(_, opts)
    opts.routes = vim.list_extend(opts.routes, {
      {
        filter = {
          any = {
            { event = "notify", find = "No information available" },
            { event = "notify", find = "multiple different client offset_encodings" },
          },
        },
        opts = { skip = true },
      },
    })
  end,
}
