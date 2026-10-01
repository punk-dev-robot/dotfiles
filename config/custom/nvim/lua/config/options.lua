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

-- Inside herdr, yank via OSC52 so it reaches the *attached client's* clipboard
-- (mac server panes viewed from Linux would otherwise pbcopy into the mac).
-- Paste from nvim's own register: OSC52 read through herdr can stall nvim.
if vim.env.HERDR_ENV then
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end
  vim.g.clipboard = {
    name = "osc52-herdr",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end

-- vim.lsp.set_log_level("debug")
-- LazyVim root dir detection
-- Patterns are checked closest-first (upward from buffer).
-- Separating package.json from .git ensures monorepo apps scope correctly:
--   <leader>ff → closest app/package dir
--   <leader>Ff → cwd (monorepo root)
vim.g.root_spec = {
  { "package.json", "tsconfig.json", "Cargo.toml", "pyproject.toml" },
  "lsp",
  { ".git" },
  "cwd",
}
-- vim.g.autoformat = false
-- LSP Server to use for Python.
-- Set to "basedpyright" to use basedpyright instead of pyright.
vim.g.lazyvim_python_lsp = "ty"
vim.g.lazyvim_python_ruff = "ruff"

vim.g.mkdp_preview_options = {
  css = { "body { font-size: 10px; }" },
}
