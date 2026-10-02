-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("t", "<A-Esc>", "<C-\\><C-n>")
-- Yank path mappings
vim.keymap.set('n', '<leader>yp', function()
  vim.fn.setreg('+', vim.fn.expand('%'))
  vim.notify('Copied: ' .. vim.fn.expand('%'))
end, { desc = 'Yank relative path' })

vim.keymap.set('n', '<leader>yP', function()
  vim.fn.setreg('+', vim.fn.expand('%:p'))
  vim.notify('Copied: ' .. vim.fn.expand('%:p'))
end, { desc = 'Yank absolute path' })

vim.keymap.set('n', '<leader>yf', function()
  vim.fn.setreg('+', vim.fn.expand('%:t'))
  vim.notify('Copied: ' .. vim.fn.expand('%:t'))
end, { desc = 'Yank filename' })

vim.keymap.set('n', '<leader>yl', function()
  local path = vim.fn.expand('%:p') .. ':' .. vim.fn.line('.')
  vim.fn.setreg('+', path)
  vim.notify('Copied: ' .. path)
end, { desc = 'Yank path:line' })

vim.keymap.set("x", "<leader>a", function()
  -- Hand the selection to the plugin through a file: works on headless servers too.
  vim.cmd('normal! "zy')
  local base = os.getenv("XDG_RUNTIME_DIR")
  if not base or base == "" then base = vim.fn.fnamemodify(vim.fn.tempname(), ":h") end
  local dir = base .. "/herdr-annotate-" .. vim.loop.getuid()
  vim.fn.mkdir(dir, "p", "0700")
  vim.fn.writefile(vim.split(vim.fn.getreg("z"), "\n"), dir .. "/selection")
  vim.fn.jobstart({ "herdr", "plugin", "action", "invoke", "annotate.capture" })
end, { desc = "Annotate in Herdr" })
