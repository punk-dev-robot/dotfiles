return {
  {
    "ThePrimeagen/git-worktree.nvim",
    config = function()
      require("telescope").load_extension("git_worktree")
      local Worktree = require("git-worktree")
      local Job = require("plenary.job")
      local Path = require("plenary.path")
      -- run yarn install on new worktree
      Worktree.on_tree_change(function(op, metadata, _)
        if op == Worktree.Operations.Create then
          -- If we're dealing with create, the path is relative to the worktree and not absolute
          -- so we need to convert it to an absolute path.
          local path = metadata.path
          if not Path:new(path):is_absolute() then
            path = Path:new():absolute()
            if path:sub(-#"/") == "/" then
              path = string.sub(path, 1, string.len(path) - 1)
            end
          end
          local worktree_path = path .. "/../" .. metadata.path .. "/"
          Job:new({
            async = true,
            on_start = function()
              print("Installing dependencies...")
            end,
            on_exit = function(_, code)
              print("Dependencies installed! Exit code:" .. code)
            end,
            on_stderr = function(_, data)
              print("Error: " .. data)
            end,
            command = "yarn",
            args = { "install" },
            cwd = worktree_path,
          }):start()
        end
      end)
      Worktree.setup({ autopush = false })
    end,
    keys = {
      {
        "<leader>gws",
        "<cmd>:lua require('telescope').extensions.git_worktree.git_worktrees()<CR>",
        desc = "Switch / Delete worktree",
      },
      {
        "<leader>gwc",
        "<cmd>:lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>",
        desc = "Add new worktree",
      },
      {
        "<leader>gwl",
        "<cmd>:lua require('telescope').extensions.git_worktree.git_worktrees()<CR>",
        desc = "Switch / Delete worktree",
      },
      {
        "<leader>gwa",
        "<cmd>:lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>",
        desc = "Add new worktree",
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>gw", group = "Worktree" },
      },
    },
  },
}
