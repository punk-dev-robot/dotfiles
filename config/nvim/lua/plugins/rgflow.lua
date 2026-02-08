return {
  {
    enabled = false,
    -- original is behind a fork atm
    -- "mangelozzi/rgflow.nvim",
    "martintrojer/rgflow.nvim",
    opts = {
      -- Set the default rip grep flags and options for when running a search via
      -- RgFlow. Once changed via the UI, the previous search flags are used for
      -- each subsequent search (until Neovim restarts).
      -- The reason it contains opposing settings (e.g. --no-ignore vs --ignore), is because then one can quickly deletes options as required E.g. since the later option "wins", deleting --ignore will make the --no-ignore flag take effect
      cmd_flags = "--smart-case --no-fixed-strings --fixed-strings --no-ignore --ignore --max-columns 500",

      -- Mappings to trigger RgFlow functions
      -- todo: use keys table instead
      default_trigger_mappings = false,
      -- These mappings are only active when the RgFlow UI (panel) is open
      default_ui_mappings = true,
      -- QuickFix window only mapping
      -- default_quickfix_mappings = true,
      colors = {
        -- The values map to vim.api.nvim_set_hl {val} parameters, see :h nvim_set_hl
        -- Examples:
        --      RgFlowInputPath    = {fg = "fg", bg="#1234FF", bold=true}
        --      RgFlowInputPattern = {link = "Title"}
        ---- UI
        -- Recommend not setting a BG so it uses the current lines BG
        RgFlowHead = { link = "TodoBgHACK" }, -- The header colors for FLAGS / PATTERN / PATH blocks
        RgFlowHeadLine = { link = "GruvboxBlue" }, -- The line along the top of the header
        -- Even though just a background, add the foreground or else when
        -- appending cant see the insert cursor
        RgFlowInputBg = { link = "GruvboxBg2" }, -- The Input lines
        -- RgFlowInputFlags = { fg = "#ebdbb2", bg = "#504945" }, -- The flag input line
        RgFlowInputFlags = { link = "GruvboxFg1" }, -- The flag input line
        RgFlowInputPattern = { link = "htmlBold" }, -- The pattern input line
        RgFlowInputPath = { link = "GruvboxFg1" }, -- The path input line
        ---- Quickfix
        RgFlowQfPattern = nil, -- The highlighting of the pattern in the quickfix results
      },
    },
    keys = {
      {
        "<leader>srg",
        function()
          require("rgflow").open_blank()
        end,
        desc = "Open pattern=blank",
      },

      {
        "<leader>srw",
        function()
          require("rgflow").open_cword()
        end,
        desc = "Open pattern=<cword>",
      },

      {
        "<leader>srW",
        function()
          require("rgflow").open_cword_path()
        end,
        desc = "Open pattern=<cword>,path=<cur_dir>",
      },

      {
        "<leader>srp",
        function()
          require("rgflow").open_paste()
        end,
        desc = "Open pattern=<unnamed_reg>",
      },

      {
        "<leader>sra",
        function()
          require("rgflow").open_again()
        end,
        desc = "Open pattern=<prev_search>",
      },

      {
        "<leader>srs",
        function()
          require("rgflow").search()
        end,
        desc = "Run a search with current params",
      },

      {
        "<leader>srx",
        function()
          require("rgflow").abort()
        end,
        desc = "Close/abort",
      },

      {
        "<leader>src",
        function()
          require("rgflow").print_cmd()
        end,
        desc = "Print last rg cmd",
      },

      {
        "<leader>sr?",
        function()
          require("rgflow").print_status()
        end,
        desc = "Print rgflow info (dev)",
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>sr", group = "RgFlow" },
      },
    },
  },
}
