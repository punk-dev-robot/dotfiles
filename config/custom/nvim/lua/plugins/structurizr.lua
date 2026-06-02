-- LikeC4 (C4 DSL) support for Neovim
if true == true then
  return {}
end

return {
  {
    -- Main plugin configuration
    "nvim-treesitter/nvim-treesitter",
    priority = 100,
    config = function()
      -- Set up logging directory
      local log_dir = vim.fn.expand("~/.cache/c4-lsp-logs")
      vim.fn.mkdir(log_dir, "p")

      -- Configuration options
      local config = {
        quiet = true, -- Set to true to disable all notifications except errors
      }

      -- Simple logging function
      local function log(msg, notify_level)
        -- Always write to log file
        local file = io.open(log_dir .. "/structurizr.log", "a")
        if file then
          file:write(string.format("[%s] %s\n", os.date("%Y-%m-%d %H:%M:%S"), msg))
          file:close()
        end

        -- Only show notification if level is provided and not in quiet mode
        -- Always show errors
        if notify_level and (not config.quiet or notify_level == vim.log.levels.ERROR) then
          vim.notify(msg, notify_level)
        end
      end

      log("Initializing LikeC4 plugin")

      -- Note: Filetype detection is set up in after/ftdetect/structurizr.vim

      -- Set commentstring for structurizr files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "structurizr",
        callback = function()
          vim.bo.commentstring = "// %s"
          log("Set commentstring for structurizr")
        end,
      })

      -- Configure TreeSitter parser
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      parser_config.structurizr = {
        install_info = {
          url = "https://github.com/josteink/tree-sitter-structurizr",
          files = { "src/parser.c" },
          branch = "master",
        },
        filetype = "structurizr",
      }

      -- Check if parser is already installed to prevent reinstall prompts
      local function is_parser_installed()
        -- Check multiple possible locations where the parser might be installed
        local possible_locations = {
          vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/parser/structurizr.so",
          vim.fn.stdpath("data") .. "/site/pack/packer/start/nvim-treesitter/parser/structurizr.so",
          vim.fn.stdpath("data") .. "/plugged/nvim-treesitter/parser/structurizr.so",
        }

        for _, path in ipairs(possible_locations) do
          if vim.fn.filereadable(path) == 1 then
            return true
          end
        end

        -- Try using the Treesitter API
        local parsers = require("nvim-treesitter.parsers")
        if parsers.has_parser("structurizr") then
          return true
        end

        -- Try using :TSInstallInfo output
        local tsinfo = vim.fn.system("nvim --headless -c 'TSInstallInfo' -c 'q'")
        if tsinfo:match("structurizr%s+[✓|✓]") then
          return true
        end

        return false
      end

      local parser_installed = is_parser_installed()
      if parser_installed then
        log("TreeSitter parser already installed")
      end

      -- Install the parser when lazy.nvim is done loading (only if needed)
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyDone",
        callback = function()
          if not parser_installed then
            vim.cmd("TSInstall structurizr")
            log("TreeSitter parser installed")
          end

          -- Explicitly set TreeSitter highlights for consistency
          -- This will override the query file with specific highlight groups
          local hl = vim.api.nvim_set_hl

          -- Create consistency for element types by using specific override colors
          local c4_types = {
            "actor",
            "softwareSystem",
            "system",
            "container",
            "component",
            "person",
            "enterprise",
            "database",
            "queue",
            "service",
          }

          -- Create consistent highlight overrides for view types
          local view_types = {
            "systemLandscape",
            "systemContext",
            "dynamic",
            "deployment",
            "filtered",
            "custom",
            "image",
          }

          -- Apply highlight overrides when colorscheme changes
          vim.api.nvim_create_autocmd("ColorScheme", {
            callback = function()
              -- Get foreground color from Type highlight group
              local type_attrs = vim.api.nvim_get_hl(0, { name = "Type" })
              local type_fg = type_attrs.fg

              -- Get foreground color from Function highlight group
              local func_attrs = vim.api.nvim_get_hl(0, { name = "Function" })
              local func_fg = func_attrs.fg

              -- Get foreground color from Keyword highlight group
              local keyword_attrs = vim.api.nvim_get_hl(0, { name = "Keyword" })
              local keyword_fg = keyword_attrs.fg

              -- Create a consistent @type highlight for all element types
              for _, name in ipairs(c4_types) do
                vim.api.nvim_set_hl(0, "@type." .. name, { fg = type_fg, italic = false })
              end

              -- Create a consistent @function highlight for all view types
              for _, name in ipairs(view_types) do
                vim.api.nvim_set_hl(0, "@function." .. name, { fg = func_fg, italic = true })
              end

              -- Force "element" keyword to use the keyword color
              vim.api.nvim_set_hl(0, "@keyword.element", { fg = keyword_fg, bold = true })
            end,
          })

          -- Execute once on load
          vim.cmd("doautocmd ColorScheme")
        end,
        once = true,
      })

      -- Path to the wrapper script (use symlinked path)
      local wrapper_script = vim.fn.stdpath("config") .. "/lua/plugins/scripts/final-wrapper.sh"

      -- Make sure the script is executable
      vim.fn.system("chmod +x " .. vim.fn.shellescape(wrapper_script))
      log("Using working wrapper: " .. wrapper_script)

      -- Command to start the LSP
      vim.api.nvim_create_user_command("StructurizrLsp", function()
        -- Get current buffer
        local bufnr = vim.api.nvim_get_current_buf()

        -- Set filetype if needed
        if vim.bo[bufnr].filetype ~= "structurizr" then
          vim.bo[bufnr].filetype = "structurizr"
          log("Set filetype to structurizr for buffer " .. bufnr)
        end

        -- Check for existing LSP clients
        local clients = vim.lsp.get_active_clients({ name = "likec4" })
        if #clients > 0 then
          log("LSP already running, attaching buffer")
          vim.lsp.buf_attach_client(bufnr, clients[1].id)
          -- Silent operation, no notification
          return
        end

        -- Start LSP client
        log("Starting LikeC4 LSP client")
        local client_id = vim.lsp.start({
          name = "likec4",
          cmd = { wrapper_script },
          root_dir = vim.fn.getcwd(),
          filetypes = { "structurizr" },
          capabilities = vim.lsp.protocol.make_client_capabilities(),
          on_exit = function(code, signal, client_id)
            log("LSP exited with code " .. code .. ", signal " .. signal .. ", client_id " .. client_id)
          end,
        }, {
          bufnr = bufnr,
        })

        if client_id then
          log("LikeC4 LSP started with ID: " .. client_id)

          -- Add a delay to check if client is still active
          vim.defer_fn(function()
            local clients = vim.lsp.get_active_clients({ name = "likec4" })
            log("Active LikeC4 clients after 2s: " .. #clients)
          end, 2000)
        else
          -- Only show error notifications
          log("Failed to start LikeC4 LSP", vim.log.levels.ERROR)
        end
      end, {})

      -- Command to check LSP status
      vim.api.nvim_create_user_command("StructurizrStatus", function()
        local clients = vim.lsp.get_active_clients({ name = "likec4" })

        if #clients > 0 then
          local client_id = clients[1].id
          local buffers = vim.lsp.get_buffers_by_client_id(client_id)
          local status = string.format("LikeC4 LSP running (ID: %d) with %d buffer(s)", client_id, #buffers)

          -- Show summary of attached buffers
          if #buffers > 0 then
            local buffer_names = {}
            for i, bufnr in ipairs(buffers) do
              if i <= 3 then -- Only show first 3 buffers to avoid cluttering
                local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
                table.insert(buffer_names, name)
              end
            end

            local buffer_text = table.concat(buffer_names, ", ")
            if #buffers > 3 then
              buffer_text = buffer_text .. ", ..." -- Indicate there are more buffers
            end

            status = status .. " - " .. buffer_text
          end

          vim.notify(status, vim.log.levels.INFO)
        else
          vim.notify("LikeC4 LSP is not running", vim.log.levels.WARN)
        end
      end, {})

      -- Command to view logs
      vim.api.nvim_create_user_command("StructurizrLogs", function()
        vim.cmd("split " .. log_dir .. "/structurizr.log")
      end, {})

      -- Command to view LSP wrapper logs
      vim.api.nvim_create_user_command("StructurizrWrapperLogs", function()
        vim.cmd("split " .. log_dir .. "/likec4-wrapper.log")
      end, {})

      -- Command to view LSP output logs
      vim.api.nvim_create_user_command("StructurizrOutput", function()
        vim.cmd("split " .. log_dir .. "/likec4-output.log")
      end, {})

      -- Command to view LSP error logs
      vim.api.nvim_create_user_command("StructurizrErrors", function()
        vim.cmd("split " .. log_dir .. "/likec4-error.log")
      end, {})

      -- Command to force attach LSP to buffer
      vim.api.nvim_create_user_command("StructurizrAttach", function()
        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_active_clients({ name = "likec4" })

        if #clients > 0 then
          log("Force attaching buffer " .. bufnr .. " to client " .. clients[1].id)
          vim.lsp.buf_attach_client(bufnr, clients[1].id)
          -- Silent successful operation
        else
          log("No LikeC4 LSP client running", vim.log.levels.ERROR)
        end
      end, {})

      -- Auto-start LSP when filetype is set
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "structurizr",
        callback = function(args)
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
              log("Auto-starting LSP for buffer " .. args.buf)
              vim.cmd("StructurizrLsp")
            end
          end, 300)
        end,
      })

      log("LikeC4 plugin initialized")
      -- Load silently - no notifications
      vim.g.structurizr_loaded = true
    end,
  },
}

