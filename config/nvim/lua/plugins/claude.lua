return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  keys = {
    { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
    { "<M-a>", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude", mode = { "n", "v", "t" } },
    -- { toggle_key, "<cmd>ClaudeCodeFocus<cr>", desc = "Claude Code", mode = { "n", "x" } },
    -- { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file",
      ft = { "NvimTree", "neo-tree", "oil" },
    },
    -- Diff management
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
  },
  opts = {
    terminal_cmd = "zsh -ic cld",
    auto_start = true,
    focus_after_send = true,

    track_selection = true,
    visual_demotion_delay_ms = 50,

    git_repo_cwd = true,

    diff_opts = {
      auto_close_on_accept = true,
      vertical_split = true,
      open_in_current_tab = false,
      keep_terminal_focus = false, -- If true, moves focus back to terminal after diff opens
    },

    terminal = {
      auto_close = true,

      ---@module "snacks"
      ---@type snacks.win.Config|{}
      snacks_win_opts = {
        position = "right",
        width = 0.33,
      },
    },
  },
}

-- return {
--   "greggh/claude-code.nvim",
--   dependencies = {
--     "nvim-lua/plenary.nvim", -- Required for git operations
--   },
--   config = function()
--     require("claude-code").setup({
--       window = {
--         position = "float",
--       },
--       keymaps = {
--         toggle = {
--           normal = "<M-a>",
--           terminal = "<M-a>",
--         },
--       },
--     })
--   end,
--   keys = {
--     { "<leader>cld", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
--     { "<leader>clc", "<cmd>ClaudeCodeContinue<cr>", desc = "Resume the last recent Claude conversation" },
--     { "<leader>clr", "<cmd>ClaudeCodeResume<cr>", desc = "Pick a Claude conversation to resume" },
--     { "<leader>clv", "<cmd>ClaudeCodeVerbose<cr>", desc = "Run Claude Code with --verbose flag" },
--   },
-- }
