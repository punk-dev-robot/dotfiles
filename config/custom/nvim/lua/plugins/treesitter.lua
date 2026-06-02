return {
  {
    "windwp/nvim-ts-autotag",
    lazy = true,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",
  },
  {
    "HiPhish/rainbow-delimiters.nvim",
    lazy = true,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    submodules = false,
    event = "VeryLazy",
  },
  {
    "nvim-treesitter/playground",
    enabled = false,
    lazy = true,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      --  vim.filetype.add({
      --    extension = { j2 = "jinja" },
      -- })
      --  vim.treesitter.language.register(lang, filetype)
      opts.autotag = {
        enable = true,
        filetypes = {
          "html",
          "gotmpl",
          "javascript",
          "typescript",
          "javascriptreact",
          "typescriptreact",
          "svelte",
          "vue",
          "tsx",
          "jsx",
          "rescript",
          "xml",
          "php",
          "markdown",
          "astro",
          "glimmer",
          "handlebars",
          "hbs",
        },
      }
      opts.playground = {
        enable = false,
        disable = {},
        updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
        persist_queries = false, -- Whether the query persists across vim sessions
        keybindings = {
          toggle_query_editor = "o",
          toggle_hl_groups = "i",
          toggle_injected_languages = "t",
          toggle_anonymous_nodes = "a",
          toggle_language_display = "I",
          focus_language = "f",
          unfocus_language = "F",
          update = "R",
          goto_node = "<cr>",
          show_help = "?",
        },
      }
    end,
  },
}
