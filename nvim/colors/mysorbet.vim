source $VIMRUNTIME/colors/sorbet.vim 
let g:colors_name = 'mysorbet'

hi Identifier guifg=#ddddef ctermfg=254
hi clear Visual
hi Visual guibg=#264f78 ctermbg=63 cterm=bold
hi NormalFloat guibg=#222230
hi link @lsp.type.punctuation Special

hi @lsp.type.namespace guifg=#aaaabb ctermbg=250

" go "namespaces" are arguably 
" a part of the identifier     
hi link @lsp.type.namespace.go Identifier 

hi link @lsp.type.recordClass Type
hi link @lsp.type.recordStruct Type
hi link @lsp.type.field Identifier
hi link @lsp.type.member Identifier
hi link @lsp.type.excludedCode Comment
hi link @lsp.type.controlKeyword Statement
hi link @lsp.type.extensionMethod Identifier
hi link @lsp.type.event Special
hi link @lsp.type.delegate Special

" RenderMarkdown groups
for i in range(1, 6)
    exe 'hi RenderMarkdownH' . i . ' gui=bold'
    exe 'hi RenderMarkdownH' . i . 'Bg guibg=#211d30 gui=bold' 
    exe 'hi link @markup.heading.' . i . ' @markup.heading.1'
endfor
hi link @markup.heading.1 Statement
hi RenderMarkdownH1Bg gui=bold,underdashed
hi link @markup.raw.markdown_inline String

hi link @lsp.type.decorator.python Special

hi link @property.json Statement
