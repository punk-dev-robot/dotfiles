return {
  {
    "neovim/nvim-lspconfig",
    keys = {
      { "<leader>vs", function()
        local clients = vim.lsp.get_active_clients({ name = "vtsls" })
        if #clients == 0 then
          print("❌ No vtsls client active")
          return
        end

        local client = clients[1]
        local buffers = vim.lsp.get_buffers_by_client_id(client.id)
        print(string.format("📊 vtsls: %d buffers, root: %s", #buffers, vim.fn.fnamemodify(client.config.root_dir or "unknown", ":~")))
      end, desc = "VTSLS Quick Status" },
    },
    init = function()
      -- VTSLS Status Command
      vim.api.nvim_create_user_command("VtslsStatus", function()
        local clients = vim.lsp.get_active_clients({ name = "vtsls" })
        if #clients == 0 then
          print("❌ No vtsls client active")
          return
        end

        local client = clients[1]
        print("=== VTSLS Status ===")
        print("Client ID: " .. client.id)
        print("Root: " .. (client.config.root_dir or "NONE"))
        print("Initialized: " .. tostring(client.initialized))
        
        -- Buffer count
        local buffers = vim.lsp.get_buffers_by_client_id(client.id)
        print("Active buffers: " .. #buffers)

        -- Memory settings
        local settings = client.config.settings
        if settings and settings.typescript and settings.typescript.tsserver then
          print("Memory limit: " .. (settings.typescript.tsserver.maxTsServerMemory or "default") .. "MB")
        end

        -- Workspace folders
        if client.workspace_folders then
          print("Workspace folders: " .. #client.workspace_folders)
          for i, folder in ipairs(client.workspace_folders) do
            if i <= 3 then -- Show first 3
              print("  - " .. vim.fn.fnamemodify(folder.name, ":~"))
            end
          end
          if #client.workspace_folders > 3 then
            print(string.format("  ... and %d more", #client.workspace_folders - 3))
          end
        end
      end, { desc = "Show VTSLS detailed status" })

      -- VTSLS Debug Command
      vim.api.nvim_create_user_command("VtslsDebug", function()
        local clients = vim.lsp.get_active_clients({ name = "vtsls" })
        if #clients == 0 then
          print("❌ No vtsls client found")
          return
        end

        local client = clients[1]
        print("=== VTSLS Debug Info ===")
        print("Client ID: " .. client.id)
        print("Root dir: " .. (client.config.root_dir or "NONE"))
        print("Initialized: " .. tostring(client.initialized))
        print("Server capabilities: " .. (client.server_capabilities and "✅" or "❌"))

        -- Current file info
        local current_buf = vim.api.nvim_get_current_buf()
        local current_file = vim.api.nvim_buf_get_name(current_buf)
        if current_file ~= "" then
          print("Current file: " .. vim.fn.fnamemodify(current_file, ":~:."))
          print("File attached: " .. (vim.lsp.buf_is_attached(current_buf, client.id) and "✅" or "❌"))
        end

        -- Show Node.js process info if available
        if client.config.cmd and client.config.cmd[1] then
          print("Node path: " .. client.config.cmd[1])
        end
      end, { desc = "Show VTSLS debug information" })

      -- VTSLS Restart Command
      vim.api.nvim_create_user_command("VtslsRestart", function()
        local clients = vim.lsp.get_active_clients({ name = "vtsls" })
        if #clients == 0 then
          print("❌ No vtsls client to restart")
          return
        end

        print("🔄 Restarting VTSLS...")
        vim.cmd("LspRestart vtsls")
        vim.defer_fn(function()
          print("✅ VTSLS restart initiated")
        end, 1000)
      end, { desc = "Restart VTSLS server" })

      -- VTSLS Memory Check Command  
      vim.api.nvim_create_user_command("VtslsMemory", function()
        local clients = vim.lsp.get_active_clients({ name = "vtsls" })
        if #clients == 0 then
          print("❌ No vtsls client active")
          return
        end

        local client = clients[1]
        local settings = client.config.settings
        
        print("=== VTSLS Memory Configuration ===")
        if settings and settings.typescript and settings.typescript.tsserver then
          local memory = settings.typescript.tsserver.maxTsServerMemory
          print("Max memory: " .. (memory or "default") .. "MB")
          
          if memory and memory >= 8192 then
            print("💪 High memory configuration active")
          elseif memory then
            print("⚠️  Limited memory configuration")
          else
            print("📊 Using default memory limits")
          end
        else
          print("❌ No memory configuration found")
        end

        -- Show buffer count as memory indicator
        local buffers = vim.lsp.get_buffers_by_client_id(client.id)
        print("Active buffers: " .. #buffers .. " (memory usage indicator)")
      end, { desc = "Check VTSLS memory configuration" })
    end,
  },
}