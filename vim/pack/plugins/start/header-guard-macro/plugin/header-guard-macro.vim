function! Header()
    let @z = expand("%:t")
    execute "normal! ggO#ifndef z€ýa?\\ v$U/\\.r_€ýaVyp€krdwidefine €ýaGo#endif"
endfunction
nmap <F2> :call Header()<CR>
