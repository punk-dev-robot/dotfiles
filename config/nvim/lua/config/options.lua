-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt
opt.winbar = "%=%m %f"
opt.conceallevel = 0
opt.wrap = true
opt.foldlevel = 99
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.relativenumber = false

-- vim.lsp.set_log_level("debug")
-- LazyVim root dir detection
-- Each entry can be:
-- * the name of a detector function like `lsp` or `cwd`
-- * a pattern or array of patterns like `.git` or `lua`.
-- * a function with signature `function(buf) -> string|string[]`
-- vim.g.root_spec = {
--   { "package.json", "project.json", "Cargo.toml", "rust-project.json", "__init__.py", ".git", ".terraform" },
--   "lsp",
--   "cwd",
-- }
-- vim.g.autoformat = false
-- LSP Server to use for Python.
-- Set to "basedpyright" to use basedpyright instead of pyright.
vim.g.lazyvim_python_lsp = "ty"
vim.g.lazyvim_python_ruff = "ruff"

vim.g.mkdp_preview_options = {
  css = { "body { font-size: 10px; }" },
}
