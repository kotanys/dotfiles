return {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = 'markdown',
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'latex-lsp/tree-sitter-latex',
        'echasnovski/mini.icons',
    },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
        latex = {
            enabled = true,
        },
        heading = {
            position = 'inline',
        },
        bullet = {
            icons = { '•', '◦', '‣', '⁃', '·' },
        },
        code = {
            border = 'thin',
        },
    },
}
