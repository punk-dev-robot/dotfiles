return {
  "selimacerbas/markdown-preview.nvim",
  -- enabled = false,
  dependencies = { "selimacerbas/live-server.nvim" },
  config = function()
    require("markdown_preview").setup({
      -- all optional; sane defaults shown
      port = 8421,
      open_browser = true,
      debounce_ms = 300,
    })
  end,
}
