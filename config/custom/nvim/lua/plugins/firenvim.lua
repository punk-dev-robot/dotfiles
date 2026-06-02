if not vim.g.started_by_firenvim then
  return {}
end

return {
  "glacambre/firenvim",
  build = ":call firenvim#install(0)",
  config = function()
    vim.opt.guifont = { "MesloLGL_Nerd_Font:h12", "MesloLGL_Nerd_Font_Mono:h12" }

    vim.api.nvim_create_autocmd({ "UIEnter" }, {
      pattern = "*",
      callback = function()
        vim.fn.timer_start(200, function()
          if vim.opt.lines:get() < 12 then
            vim.opt.lines = 12
          end
        end)
      end,
    })

    vim.g.firenvim_config = {
      localSettings = {
        [".*"] = {
          takeover = "never",
          cmdline = "neovim",
        },
      },
    }

    vim.api.nvim_create_autocmd({ "BufEnter" }, {
      pattern = "www.boot.dev_*.txt",
      command = "setlocal filetype=python",
    })

    vim.api.nvim_create_autocmd({ "BufEnter" }, {
      pattern = "github.com_*.txt",
      command = "setlocal filetype=markdown",
    })

  end,
}
