-- https://github.com/rmagatti/goto-preview/wiki/Advanced-Configurations#open-preview-window-using-telescope-esque-bindings
local M = {}

M.select_to_edit_map = {
  default = "edit",
  horizontal = "new",
  vertical = "vnew",
  tab = "tabedit",
}

function M.open_file(orig_window, filename, cursor_position, command)
  if orig_window ~= 0 and orig_window ~= nil then
    vim.api.nvim_set_current_win(orig_window)
  end
  pcall(vim.cmd, string.format("%s %s", command, filename))
  vim.api.nvim_win_set_cursor(0, cursor_position)
end

function M.open_preview(preview_win, type)
  local gtp = require("goto-preview")
  return function()
    local command = M.select_to_edit_map[type]
    local orig_window = vim.api.nvim_win_get_config(preview_win).win
    local cursor_position = vim.api.nvim_win_get_cursor(preview_win)
    local filename = vim.api.nvim_buf_get_name(0)

    vim.api.nvim_win_close(preview_win, gtp.conf.force_close)
    M.open_file(orig_window, filename, cursor_position, command)

    local buffer = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_del_keymap(buffer, "n", "<C-v>")
    vim.api.nvim_buf_del_keymap(buffer, "n", "<CR>")
    vim.api.nvim_buf_del_keymap(buffer, "n", "<C-x>")
    vim.api.nvim_buf_del_keymap(buffer, "n", "<C-t>")
  end
end

function M.post_open_hook(buf, win)
  vim.keymap.set("n", "<C-v>", M.open_preview(win, "vertical"), { buffer = buf })
  vim.keymap.set("n", "<CR>", M.open_preview(win, "default"), { buffer = buf })
  vim.keymap.set("n", "<C-x>", M.open_preview(win, "horizontal"), { buffer = buf })
  vim.keymap.set("n", "<C-t>", M.open_preview(win, "tab"), { buffer = buf })
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, false)
  end)
end

return {
  "rmagatti/goto-preview",
  keys = {
    { "gl", "", desc = "+lsp goto preview" },
    { "gld", "<cmd>lua require('goto-preview').goto_preview_definition()<CR>", desc = "definition" },
    { "glt", "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>", desc = "type definition" },
    { "gli", "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>", desc = "implementation" },
    { "glD", "<cmd>lua require('goto-preview').goto_preview_declaration()<CR>", desc = "declaration" },
    { "glr", "<cmd>lua require('goto-preview').goto_preview_references()<CR> ", desc = "references" },
    { "glx", "  <cmd>lua require('goto-preview').close_all_win()<CR>", desc = "close all" },
  },
  opts = {
    width = 120, -- Width of the floating window
    height = 15, -- Height of the floating window
    border = { "↖", "─", "┐", "│", "┘", "─", "└", "│" }, -- Border characters of the floating window
    default_mappings = false, -- Bind default mappings
    debug = false, -- Print debug information
    opacity = nil, -- 0-100 opacity level of the floating window where 100 is fully transparent.
    resizing_mappings = false, -- Binds arrow keys to resizing the floating window.
    post_open_hook = M.post_open_hook, -- A function taking two arguments, a buffer and a window to be ran as a hook.
    post_close_hook = nil, -- A function taking two arguments, a buffer and a window to be ran as a hook.
    references = { -- Configure the telescope UI for slowing the references cycling window.
      telescope = require("telescope.themes").get_dropdown({ hide_preview = false }),
    },
    -- These two configs can also be passed down to the goto-preview definition and implementation calls for one off "peak" functionality.
    focus_on_open = true, -- Focus the floating window when opening it.
    dismiss_on_move = false, -- Dismiss the floating window when moving the cursor.
    force_close = true, -- passed into vim.api.nvim_win_close's second argument. See :h nvim_win_close
    bufhidden = "wipe", -- the bufhidden option to set on the floating window. See :h bufhidden
    stack_floating_preview_windows = true, -- Whether to nest floating windows
    preview_window_title = { enable = true, position = "left" }, -- Whether to set the preview window title as the filename
  },
}
