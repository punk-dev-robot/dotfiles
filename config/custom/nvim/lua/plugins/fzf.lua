-- foo.*bar -- *.lua !*spec*
return {
  "ibhagwan/fzf-lua",
  keys = {
    { "<leader>/", LazyVim.pick("live_grep_glob"), desc = "Grep (Root Dir)" },
    { "<leader>sg", LazyVim.pick("live_grep_glob"), desc = "Grep glob(Root Dir)" },
    { "<leader>sG", LazyVim.pick("live_grep_glob", { root = false }), desc = "Grep glob(cwd)" },
  },
  opts = function(_, opts)
    local actions = require("fzf-lua.actions")
    return vim.tbl_deep_extend("force", opts, {
      actions = {
        files = {
          ["default"] = actions.file_edit,
          ["ctrl-x"] = actions.file_split,
          ["ctrl-v"] = actions.file_vsplit,
          ["ctrl-t"] = actions.file_tabedit,
          ["alt-q"] = actions.file_sel_to_qf,
          ["alt-t"] = require("trouble.sources.fzf").actions.open,
        },
      },
    })
  end,
}
