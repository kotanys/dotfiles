return {
    { -- Adds SubstituteCase command and others
        "vim-scripts/keepcase.vim",
        commit = "00e2bfd",
    },
    { -- Use relative numbers for active buffer outside of insert mode; normal numbers otherwise
        "jeffkreeftmeijer/vim-numbertoggle",
        commit = "075b747",
    },
    { -- It's in the name
        "gen740/SmoothCursor.nvim",
        commit = "12518b2",
        opts = {
            threshold = 1
        }
    },
    { -- Show unstaged git changes in sign column
        "airblade/vim-gitgutter",
    },
    { -- Icon library
        "echasnovski/mini.icons",
        opts = {}
    },
    { -- Press F2 to add a header guard in C/C++ headers
        "kotanys/header-guard-macro",
    },
    { -- Git frontend
        "tpope/vim-fugitive",
    },
    { -- 1C (BSL) language support
        "l1ike/vim1c",
        commit = "d32f09b",
    },
    { -- Better-looking inline diagnostics
        "rachartier/tiny-inline-diagnostic.nvim",
        dependencies = { "neovim/nvim-lspconfig" },
        config = function ()
            require("tiny-inline-diagnostic").setup({
                preset = "classic",
                options = {
                    multilines = {
                        enabled = true,
                        always_show = true,
                        severity = { vim.diagnostic.severity.ERROR },
                    },
                    severity = { -- HINTs only visible in <C-w>d
                        vim.diagnostic.severity.ERROR,
                        vim.diagnostic.severity.WARN,
                        vim.diagnostic.severity.INFO,
                    },
                },
            })
            vim.diagnostic.config({ virtual_text = false })
        end
    },
}
