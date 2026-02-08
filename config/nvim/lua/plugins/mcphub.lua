return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for async operations
  },
  build = "npm install -g mcp-hub@latest",
  config = function()
    require("mcphub").setup()
  end,
  keys = {
    { "<leader>am", "<cmd>MCPHub<cr>", desc = "MCP Hub" },
  },
}
