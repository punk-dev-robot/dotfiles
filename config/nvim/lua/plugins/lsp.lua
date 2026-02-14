return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          source = "always",
          border = "rounded",
        },
      },
      -- Increase timeout for large projects
      format_options = {
        timeout_ms = 10000, -- 10 seconds for 64GB system
      },
      servers = {
        jsonls = {
          settings = {
            json = {
              format = { enable = false },
              validate = { enable = true },
            },
          },
        },
        yamlls = {
          settings = {
            yaml = {
              customTags = { "!reference sequence" },
              format = { enable = false },
            },
          },
        },
        basedpyright = {
          enabled = false,
          disableOrganizeImports = true,
        },
        pyright = {
          enabled = false,
          disableOrganizeImports = true,
        },
        vtsls = {
          single_file_support = false,
          -- Comment out custom root_dir to use default detection
          -- root_dir = function()
          --   local lazyvimRoot = require("lazyvim.util.root")
          --   return lazyvimRoot.git() or lazyvimRoot.detect()
          -- end,
          -- Less aggressive debouncing for powerful system
          flags = {
            debounce_text_changes = 150, -- 150ms delay
          },
          settings = {
            -- VTSLS specific optimizations
            vtsls = {
              autoUseWorkspaceTsdk = true,
              enableMoveToFileCodeAction = true, -- Can enable with 64GB RAM
              experimental = {
                enableProjectDiagnostics = true, -- Can enable with 64GB RAM
                completion = {
                  enableServerSideFuzzyMatch = true,
                  entriesLimit = 200, -- Increased for 64GB system
                },
                maxInlayHintLength = 80,
                maxFileSize = 52428800, -- 50MB max file size
              },
              refactoring = {
                enable = true,
                maxFileSize = 20971520, -- 20MB for refactoring
              },
              tsserver = {
                globalPlugins = {},
                nodePath = "/usr/bin/node",
              },
            },

            -- TypeScript settings
            typescript = {
              surveys = { enabled = false },
              updateImportsOnFileMove = { enabled = "prompt" }, -- Can enable with 64GB

              -- Workspace symbols optimization
              workspaceSymbols = {
                scope = "allOpenProjects", -- Can search more with 64GB
                excludeLibrarySymbols = false, -- Include library symbols
              },

              -- Enable some inlay hints for better DX
              inlayHints = {
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = false },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },

              -- Enhanced suggestions for 64GB system
              suggest = {
                enabled = true,
                completeFunctionCalls = true, -- Better UX
                includeCompletionsForImportStatements = true,
                includeAutomaticOptionalChainCompletions = true,

                -- Enable more features
                classMemberSnippets = { enabled = true },
                includeCompletionsForModuleExports = true, -- Can enable with 64GB
                includeCompletionsWithSnippetText = true,
                includeCompletionsWithInsertText = true,
                includeCompletionsWithClassMemberSnippets = true,
                includeCompletionsWithObjectLiteralMethodSnippets = true,

                -- Generous limits for 64GB system
                autoImports = true,
                completionsCacheSize = 50000, -- Large cache
                maxSuggestionCount = 500, -- Many suggestions

                -- Trigger settings
                suggestOnTriggerCharacters = true,
                triggerCharacters = { ".", '"', "'", "/", "@", "<", "-", " " },
              },

              -- Preferences
              preferences = {
                -- Import handling
                importModuleSpecifierPreference = "shortest",
                importModuleSpecifierEnding = "minimal",
                includePackageJsonAutoImports = "auto", -- Can use auto with 64GB
                preferTypeOnlyAutoImports = true,

                -- Enable more features
                allowTextChangesInNewFiles = true,
                allowRenameOfImportPath = true,
                providePrefixAndSuffixTextForRename = true,
                provideRefactorNotApplicableReason = true,

                -- Enable inlay hints preferences
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = true,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,

                -- Performance settings
                disableSuggestions = false,
                lazyConfiguredProjectsFromExternalProject = false, -- Load everything

                -- Auto-import exclusions (minimal)
                autoImportFileExcludePatterns = {
                  "node_modules/@types/node/**", -- Only exclude Node types
                },
              },

              -- Disable formatting (use ESLint)
              format = { enable = false },

              -- TSServer configuration for 64GB system
              tsserver = {
                -- Memory settings - use 24GB for TypeScript
                maxTsServerMemory = 24576, -- 24GB

                -- Logging
                logVerbosity = "verbose",
                logFile = "/tmp/tsserver.log",

                -- Performance
                useSyntaxServer = "auto", -- Let it decide
                useSingleInferredProject = false, -- Allow multiple projects
                useInferredProjectPerProjectRoot = true, -- Better for monorepo
                disableAutomaticTypeAcquisition = false, -- Can enable with 64GB

                -- Plugin management
                pluginPaths = {},
                globalPlugins = {},
                enableTracing = false,

                -- Project configuration
                projectLoadingTimeout = 120, -- 2 minutes timeout

                -- Experimental features - all enabled for 64GB
                experimental = {
                  cacheSizeLimit = 8192, -- 8GB cache
                  enableInMemoryProjectCache = true,
                  enableTsServerTracing = false,
                  maxNodeModuleJsDepth = 2, -- Can analyze some node_modules
                },

                -- Watch options
                watchOptions = {
                  watchFile = "useFsEvents",
                  watchDirectory = "useFsEvents",
                  fallbackPolling = "dynamicPriority",
                  synchronousWatchDirectory = false,
                  excludeDirectories = {
                    "**/node_modules/@types",
                    "**/node_modules/.cache",
                    "**/node_modules/.vite",
                    "**/.git/objects",
                    "**/.git/subtree-cache",
                    "**/dist",
                    "**/.nx-cache",
                    "**/coverage",
                    "**/.next",
                    "**/build",
                    "**/.yarn/cache",
                    "**/.yarn/unplugged",
                    "**/.pnp.*",
                    "**/tmp",
                    "**/temp",
                    "**/.cache",
                    "**/.turbo",
                    "**/.serverless",
                    "**/.sst",
                  },
                  excludeFiles = {
                    "**/*.log",
                    "**/*.tsbuildinfo",
                    "**/package-lock.json",
                    "**/yarn.lock",
                    "**/pnpm-lock.yaml",
                    "**/*.map",
                    "**/*.min.js",
                  },
                },
              },
            },
          },
        },
      },
      setup = {
        jsonls = function()
          Snacks.util.lsp.on({}, function(_, client)
            if client.name == "jsonls" then
              client.server_capabilities.documentFormattingProvider = false
            end
          end)
        end,
        eslint = function()
          Snacks.util.lsp.on({}, function(_, client)
            if client.name == "eslint" then
              client.server_capabilities.documentFormattingProvider = true
            elseif client.name == "tsserver" or client.name == "vtsls" then
              client.server_capabilities.documentFormattingProvider = false
            end
          end)
        end,
        vtsls = function(_, opts)
          local nodePath = "/usr/bin/node"
          local masonRoot = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
          local vtslsPath = masonRoot .. "/bin/vtsls"

          opts.cmd = {
            nodePath,
            vtslsPath,
            "--stdio",
            "--max-old-space-size=24576", -- 24GB for 64GB system
            "--max-semi-space-size=2048", -- 2GB semi-space
            "--huge-max-old-generation-size",
          }

          -- vim.notify(vim.inspect(opts))
          opts.cmd_env = {
            -- TSS_LOG = "-level verbose -file /tmp/tsserver.log",
            NODE_OPTIONS = "--max-old-space-size=24576 --huge-max-old-generation-size",
            -- VTSLS_DEBUG = "1",
            TSC_NONPOLLING_WATCHER = "true",
            TSC_WATCHFILE = "useFsEventsOnParentDirectory",
            TSC_WATCHDIRECTORY = "useFsEvents",
          }

          -- Initialization options
          opts.init_options = {
            hostInfo = "neovim",
            maxTsServerMemory = 24576, -- 24GB
            npmLocation = "/usr/bin/npm",
            locale = "en",
            preferences = {
              quoteStyle = "single",
              importModuleSpecifierPreference = "shortest",
              includePackageJsonAutoImports = "auto",
              allowTextChangesInNewFiles = true,
              providePrefixAndSuffixTextForRename = true,
            },
          }

          -- Custom handlers for performance
          opts.handlers = {
            -- Less aggressive debouncing for 64GB system
            ["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
              delay = 100, -- Only 100ms delay
              underline = true,
              virtual_text = false,
              signs = true,
              update_in_insert = false,
            }),
          }

          -- On attach optimizations
          opts.on_attach = function(client, bufnr)
            -- Keep semantic tokens with 64GB RAM
            -- client.server_capabilities.semanticTokensProvider = nil

            -- Less aggressive performance limits
            vim.bo[bufnr].synmaxcol = 500 -- Allow more syntax highlighting

            -- Note: updatetime is a global option, not buffer-local
            -- Set it globally if needed: vim.opt.updatetime = 1000
          end
        end,
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      automatic_enable = {
        exclude = {
          "helm-ls",
        },
      },
    },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
  },
  {
    "chrisgrieser/nvim-lsp-endhints",
    event = "LspAttach",
    opts = {},
  },
  -- Add buffer limiting on startup (but allow more buffers for 64GB system)
  {
    "folke/lazy.nvim",
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          -- Allow up to 10 buffers with 64GB RAM
          local buffers = vim.fn.getbufinfo({ buflisted = 1 })
          if #buffers > 10 then
            local current = vim.api.nvim_get_current_buf()
            -- Keep the 10 most recent buffers
            local to_delete = #buffers - 10
            for i, buf in ipairs(buffers) do
              if i <= to_delete and buf.bufnr ~= current then
                vim.api.nvim_buf_delete(buf.bufnr, { force = true })
              end
            end
            vim.notify(string.format("Closed %d extra buffers to prevent LSP overload", to_delete), vim.log.levels.INFO)
          end
        end,
      })

      -- Less aggressive garbage collection with 64GB RAM
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
        callback = function()
          -- Only collect garbage occasionally
          if math.random() < 0.1 then -- 10% chance
            collectgarbage("step", 50)
          end
        end,
      })

      -- Set global options for TypeScript development
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
        callback = function()
          vim.opt.updatetime = 300 -- Faster updates with 64GB RAM
        end,
      })
    end,
  },
}
