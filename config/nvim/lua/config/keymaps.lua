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
