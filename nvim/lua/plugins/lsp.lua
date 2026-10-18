---@param lsp string
---@param config vim.lsp.Config?
local function lsp_enable(lsp, config)
    if config ~= nil then
        vim.lsp.config(lsp, config)
    end
    -- TODO ask user for permission to download from Mason?
    vim.lsp.enable(lsp)
end

local function setup_gopls()
    lsp_enable('gopls', {
        settings = {
            gopls = {
                analyses = {
                    unusedparams = true,
                    shadow = true,
                },
                staticcheck = true,
                semanticTokens = false,
            }
        }
    })

    -- I don't like automatic formatting, but it seems to be the norm
    -- for golang development (this makes Go source files always
    -- comply with the gofmt style)
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("lsp.golang.formatting", {}),
        desc = 'Automatic Golang formatting',
        pattern = "*.go",
        callback = function()
            require('go.format').goimports()
        end
    })
end

function SetupLsps()
    if vim.g.nolsp then
        return
    end
    setup_gopls()

    lsp_enable("basedpyright", {
        settings = {
            basedpyright = {
                analysis = {
                    typeCheckingMode = "basic",
                },
            },
        },
    })

    lsp_enable("bashls", {
        settings = {
            bashIde = {
                -- Ignore:
                --  1090,1091: 'can't follow file' warnings
                --  2155: 'return code masking' warnings
                shellcheckArguments = "--exclude=1090,1091,2155",
                shfmt = {
                    keepPadding = true,
                },
            },
        }
    })

    lsp_enable("powershell_es", {
        bundle_path = (function()
            if require('mason-registry').is_installed('powershell-editor-services') then
                return vim.env.HOME ..
                    '/.local/share/nvim/mason/packages/powershell-editor-services/PowerShellEditorServices'
            else
                vim.notify(
                    "Can't find bundle path of powershell_es language server.\n" ..
                    "Install it via mason (powershell-editor-services) or modify lsp.lua.",
                    vim.log.levels.WARN
                )
            end
        end)(),
        init_options = {
            enableProfileLoading = false,
        },
    })

    lsp_enable('lua_ls', {
        on_init = function(client)
            if client.workspace_folders then
                -- If not inside Neovim config directory,
                -- DON'T load it's libraries
                local path = client.workspace_folders[1].name
                if
                    path ~= vim.fn.stdpath('config')
                    and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
                then
                    return
                end
            end

            -- Else, DO load Neovim's libraries

            ---@diagnostic disable-next-line: param-type-mismatch
            client.config.settings.Lua = {
                runtime = {
                    version = 'LuaJIT',
                    path = {
                        'lua/?.lua',
                        'lua/?/init.lua',
                        'lua/plugins/?.lua'
                    },
                },
                workspace = {
                    checkThirdParty = false,
                    library = { vim.env.VIMRUNTIME },
                },
                telemetry = false,
            }
        end,
        settings = {
            Lua = {}
        },
        root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git", "init.lua", },
    })


    -- roslyn_ls requires an html language server for razor support.
    -- roslyn.razor package used here is taken from
    -- https://github.com/seblyng/roslyn.nvim/tree/b4954e9/lua/roslyn/razor
    local razor_handlers = require("roslyn.razor.handlers")
    local old_on_attach_roslyn = vim.lsp.config.roslyn_ls.on_attach
    lsp_enable("roslyn_ls", {
        on_attach = function(client, bufnr)
            -- vim.diagnostic.enable(false, { bufnr = bufnr })
            if old_on_attach_roslyn ~= nil then
                old_on_attach_roslyn(client, bufnr)
            end
        end,
        filetypes = { "cs", "razor" },
        settings = {
            ["csharp|background_analysis"] = {
                dotnet_analyzer_diagnostics_scope = "openFiles",
                dotnet_compiler_diagnostics_scope = "openFiles"
            },
            ["csharp|code_lens"] = {
                dotnet_enable_references_code_lens = false
            },
            razor = {
                language_server = {
                    cohosting_enabled = true
                }
            }
        },
        handlers = {
            ["razor/updateHtml"] = razor_handlers.html_update,
            ["textDocument/documentColor"] = razor_handlers.forward,
            ["textDocument/colorPresentation"] = razor_handlers.forward,
            ["textDocument/foldingRange"] = razor_handlers.forward,
            ["textDocument/hover"] = razor_handlers.forward,
            ["textDocument/documentHighlight"] = razor_handlers.forward,
            ["textDocument/completion"] = razor_handlers.forward,
            ["textDocument/reference"] = razor_handlers.forward,
            ["textDocument/implementation"] = razor_handlers.forward,
            ["textDocument/definition"] = razor_handlers.forward,
            ["textDocument/signatureHelp"] = razor_handlers.forward,
            ["textDocument/formatting"] = razor_handlers.forward,
            ["textDocument/onTypeFormatting"] = razor_handlers.forward,
        }
    })


    lsp_enable("dockerls")

    lsp_enable("html")
    lsp_enable("jsonls")
    lsp_enable("cssls")
    lsp_enable("ts_ls")

    lsp_enable("tinymist")

    local old_on_attach_clangd = vim.lsp.config.clangd.on_attach
    lsp_enable("clangd", {
        ---@param client vim.lsp.Client
        ---@param bufnr integer
        on_attach = function(client, bufnr)
            if old_on_attach_clangd ~= nil then
                old_on_attach_clangd(client, bufnr)
            end
            vim.api.nvim_buf_create_user_command(bufnr, 'LspClangdRenameSourceHeader', function()
                require("clangd.rename_source_header").rename_source_header(client, bufnr)
            end, { desc = 'Rename both source and header' })
        end,

        root_markers = { ".clangd", ".clang-tidy", "compile_commands.json",
            "compile_flags.txt", "configure.ac", ".git" },
        cmd = { "clangd", "--clang-tidy", "--pch-storage=memory", "--fallback-style=Google" },
    })


    vim.api.nvim_create_user_command("LspInfo", ":checkhealth vim.lsp", {})
    vim.api.nvim_create_user_command("LspLog", ":sp " .. vim.fn.stdpath("state") .. "/lsp.log", {})
end

return {
    {
        "neovim/nvim-lspconfig",
        config = SetupLsps,
    },
    {
        "williamboman/mason.nvim",
        opts = {
            registries = {
                "github:mason-org/mason-registry",
            },
        },
    },
    -- LSP specific plugins go below --
    {
        url = "https://codeberg.org/mfussenegger/nvim-jdtls",
        ft = { "java" },
        enabled = function ()
            return vim.fn.executable("jdtls") == 1
        end,
        config = function()
            local jdtls = require('jdtls')
            local lombok_jar = vim.fn.stdpath("data") .. "/mason/packages/jdtls/lombok.jar"
            local jdtls_config = {
                cmd = {
                    'jdtls',
                    '-data',
                    vim.env.HOME .. "/.cache/jdtls-workspace/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t'),
                    '-javaagent:' .. lombok_jar
                },
                settings = {
                    java = {
                        annotationProcessing = {
                            enabled = true,
                        },
                        configuration = {
                            runtimes = {
                                {
                                    name = "JavaSE-21",
                                    path = "/usr/lib/jvm/java-21-openjdk",
                                },
                                {
                                    name = "JavaSE-25",
                                    path = "/usr/lib/jvm/java-25-openjdk",
                                    default = true,
                                },
                            },
                        },
                    },
                },
                init_options = {
                    bundles = { lombok_jar },
                },
            }
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'java',
                group = vim.api.nvim_create_augroup('lsp.java', {}),
                callback = function()
                    jdtls.start_or_attach(jdtls_config)
                end
            })
        end
    },
    {
        "ray-x/go.nvim",
        dependencies = {
            "ray-x/guihua.lua",
            "neovim/nvim-lspconfig",
        },
        opts = {},
        ft = { "go", 'gomod' },
        build = ':lua require("go.install").update_all()'
    },
}
