return {
  "nvim-neo-tree/neo-tree.nvim",
  enabled = false,
  opts = {
    -- sync_root_with_cwd = true,
    respect_buf_cwd = true,
    update_focused_file = {
      enable = true,
      -- update_root = true,
    },
    event_handlers = {
      {
        event = "file_opened",
        handler = function(file_path)
          --auto close
          require("neo-tree").close_all()
        end,
      },
    },
  },
}
