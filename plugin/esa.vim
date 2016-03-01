"=============================================================================
" File: esa.vim
" Author: Masato Yamamoto <jajkeqos@gmail.com>
" Last Change: 01-Mar-2016.
" Version: 0.1
" WebPage: http://github.com/upamune/esa.vim
" License: BSD
" script type: plugin

if &compatible || (exists('g:loaded_esa_vim') && g:loaded_esa_vim)
  finish
endif
let g:loaded_esa_vim = 1

function! s:CompleteArgs(arg_lead,cmdline,cursor_pos)
    return filter(copy(["-b", "-w", "--browser", "--wip"
                \ ]), 'stridx(v:val, a:arg_lead)==0')
endfunction

command! -nargs=? -range=% -bang -complete=customlist,s:CompleteArgs Esa :call esa#Esa(<count>, "<bang>", <line1>, <line2>, <f-args>)

" vim:set et:
