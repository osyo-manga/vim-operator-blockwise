scriptencoding utf-8
if exists('g:loaded_operator_blockwise')
  finish
endif
let g:loaded_operator_blockwise = 1

let s:save_cpo = &cpo
set cpo&vim


nnoremap <expr> <Plug>(operator-blockwise-yank)   operator#blockwise#mapexpr("y")
nnoremap <expr> <Plug>(operator-blockwise-delete) operator#blockwise#mapexpr("d")
nnoremap <expr> <Plug>(operator-blockwise-change) operator#blockwise#mapexpr("c")

nnoremap <expr> <Plug>(operator-blockwise-yank-head)   operator#blockwise#mapexpr_head("y")
nnoremap <expr> <Plug>(operator-blockwise-delete-head) operator#blockwise#mapexpr_head("d")
nnoremap <expr> <Plug>(operator-blockwise-change-head) operator#blockwise#mapexp

nnoremap <expr> <Plug>(operator-blockwise-yank-tail)   operator#blockwise#mapexpr_tail("y")
nnoremap <expr> <Plug>(operator-blockwise-delete-tail) operator#blockwise#mapexpr_tail("d")
nnoremap <expr> <Plug>(operator-blockwise-change-tail) operator#blockwise#mapexpr_tail("c")


let &cpo = s:save_cpo
unlet s:save_cpo
