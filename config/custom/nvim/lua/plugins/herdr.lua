if vim.env.HERDR_ENV ~= "1" then
  return {}
end

return {
  "lmilojevicc/herdr-splits.nvim",
  event = "VeryLazy",
  opts = {
    resize_keys = {
      left = "<C-Left>",
      down = "<C-Down>",
      up = "<C-Up>",
      right = "<C-Right>",
    },
  },
  keys = {
    { "<C-h>", function() require("herdr-splits").move_cursor_left() end, desc = "Navigate left (Nvim/Herdr)" },
    { "<C-j>", function() require("herdr-splits").move_cursor_down() end, desc = "Navigate down (Nvim/Herdr)" },
    { "<C-k>", function() require("herdr-splits").move_cursor_up() end, desc = "Navigate up (Nvim/Herdr)" },
    { "<C-l>", function() require("herdr-splits").move_cursor_right() end, desc = "Navigate right (Nvim/Herdr)" },
    { "<C-Left>", function() require("herdr-splits").resize_left() end, desc = "Resize left (Nvim/Herdr)" },
    { "<C-Down>", function() require("herdr-splits").resize_down() end, desc = "Resize down (Nvim/Herdr)" },
    { "<C-Up>", function() require("herdr-splits").resize_up() end, desc = "Resize up (Nvim/Herdr)" },
    { "<C-Right>", function() require("herdr-splits").resize_right() end, desc = "Resize right (Nvim/Herdr)" },
  },
}
