if not vim.env.TMUX or vim.env.TMUX == "" then
  return {}
end

return {
  {
    "aserowy/tmux.nvim",
    dependencies = { "folke/which-key.nvim" },

    keys = {
      -- navigation
      { "<C-h>", "<cmd>lua require'tmux'.move_left()<cr>", mode = { "n", "i" }, desc = "Go to left window " },
      { "<C-j>", "<cmd>lua require'tmux'.move_bottom()<cr>", mode = { "n", "i" }, desc = "Go to lower window " },
      { "<C-k>", "<cmd>lua require'tmux'.move_top()<cr>", mode = { "n", "i" }, desc = "Go to top window " },
      { "<C-l>", "<cmd>lua require'tmux'.move_right()<cr>", mode = { "n", "i" }, desc = "Go to right window " },

      -- resizing
      { "<C-Left>", "<cmd>lua require'tmux'.resize_left()<cr>", mode = { "n", "i" }, desc = "Resize window left " },
      { "<C-Down>", "<cmd>lua require'tmux'.resize_bottom()<cr>", mode = { "n", "i" }, desc = "Resize window bottom " },
      { "<C-Up>", "<cmd>lua require'tmux'.resize_top()<cr>", mode = { "n", "i" }, desc = "Resize window top " },
      { "<C-Right>", "<cmd>lua require'tmux'.resize_right()<cr>", mode = { "n", "i" }, desc = "Resize window right " },
    },

    opts = {
      copy_sync = {
        -- enables copy sync. by default, all registers are synchronized.
        -- to control which registers are synced, see the `sync_*` options.
        enable = false,
        -- ignore specific tmux buffers e.g. buffer0 = true to ignore the
        -- first buffer or named_buffer_name = true to ignore a named tmux
        -- buffer with name named_buffer_name :)
        ignore_buffers = { empty = false },
        -- TMUX >= 3.2: all yanks (and deletes) will get redirected to system
        -- clipboard by tmux
        redirect_to_clipboard = false,
        -- offset controls where register sync starts
        -- e.g. offset 2 lets registers 0 and 1 untouched
        register_offset = 0,
        -- overwrites vim.g.clipboard to redirect * and + to the system
        -- clipboard using tmux. If you sync your system clipboard without tmux,
        -- disable this option!
        sync_clipboard = false,
        -- synchronizes registers *, +, unnamed, and 0 till 9 with tmux buffers.
        sync_registers = false,
        -- syncs deletes with tmux clipboard as well, it is adviced to
        -- do so. Nvim does not allow syncing registers 0 and 1 without
        -- overwriting the unnamed register. Thus, ddp would not be possible.
        sync_deletes = false,
        -- syncs the unnamed register with the first buffer entry from tmux.
        sync_unnamed = false,
      },
      navigation = {
        -- cycles to opposite pane while navigating into the border
        cycle_navigation = true,
        -- enables default keybindings (C-hjkl) for normal mode
        enable_default_keybindings = false,
        -- prevents unzoom tmux when navigating beyond vim border
        persist_zoom = false,
      },
      resize = {
        -- enables default keybindings (A-hjkl) for normal mode
        enable_default_keybindings = false,
        -- sets resize steps for x axis
        resize_step_x = 5,
        -- sets resize steps for y axis
        resize_step_y = 2,
      },
    },
  },
  {
    -- tmux nvim status integration
    -- also see: https://github.com/b0o/nvim-conf/blob/main/lua/user/plugins/status.lua
    "vimpostor/vim-tpipeline",
    -- enabled = false,
    -- cond = function()
    --   return vim.env.TMUX ~= nil
    -- end,
    dependencies = {
      "nvim-lualine/lualine.nvim",
    },
    -- lazy = false,
    event = "VeryLazy",
    init = function()
      vim.cmd.hi({ "link", "StatusLine", "WinSeparator" })
      vim.o.laststatus = 0
      vim.g.tpipeline_statusline = ""
      vim.defer_fn(function()
        vim.o.laststatus = 0
      end, 0)
      vim.g.tpipeline_autoembed = 0
      vim.g.tpipeline_focuslost = 1
      vim.g.tpipeline_cursormoved = 1
      -- vim.g.tpipeline_preservebg = 0
      -- vim.g.tpipeline_fillcentre = 0
      -- TODO: fix
      -- vim.g.tpipeline_clearstl = 1 -- horizontal split fix
      vim.g.tpipeline_restore = 0
      vim.o.fcs = "stlnc:─,stl:─,vert:│"
      -- vim.opt.fillchars:append({ eob = " " })
      vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "laststatus",
        callback = function()
          if vim.o.laststatus ~= 0 then
            vim.notify("Auto-setting laststatus to 0")
            vim.o.laststatus = 0
          end
        end,
      })
    end,
  },
}
