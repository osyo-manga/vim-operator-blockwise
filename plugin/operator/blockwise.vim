scriptencoding utf-8
if exists('g:loaded_blockwise')
  finish
endif
let g:loaded_blockwise = 1

let s:save_cpo = &cpo
set cpo&vim

nnoremap <expr> <Plug>(operator-blockwise-yank) operator#blockwise#mapexpr("y")
nnoremap <expr> <Plug>(operator-blockwise-delete) operator#blockwise#mapexpr("d")
nnoremap <expr> <Plug>(operator-blockwise-change) operator#blockwise#mapexpr("c")


let &cpo = s:save_cpo
unlet s:save_cpo
