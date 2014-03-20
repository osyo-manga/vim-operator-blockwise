scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim


function! s:region(textobj)
	return get(textobj#blockwise#region_from_textobj(a:textobj), 1, [])
endfunction


function! s:as_cursorpos(pos)
	if empty(a:pos)
		return [0, 0, 0, 0]
	endif
	return [0, a:pos[0], a:pos[1], 0]
endfunction



function! s:mapping(name, ...)
	let mode = get(a:, 1, "")
	redir => map
		silent! execute mode . "map" a:name
	redir END
	let pat = '^' . (mode == "" ? '.' : mode) . '\s\+' . a:name
	return filter(split(map, "\n"), 'v:val =~ pat')
endfunction


function! s:mapcheck_once(name, ...)
	let mode = get(a:, 1, "")
	if mapcheck(a:name, mode) == ""
		return 0
	endif
	redir => map
		silent! execute mode . "map" a:name
	redir END
	let pat = '^' . (mode == "" ? '.' : mode) . '\s\+' . a:name
	return len(filter(split(map, "\n"), 'v:val =~ pat')) == 1
endfunction

function! s:has_motion(name)
	return s:mapcheck_once(a:name, "o") || !empty(textobj#multitextobj#region_from_textobj(a:name)[1])
endfunction


function! s:getchar()
	let char = getchar()
	return type(char) == type(0) ? nr2char(char) : char
endfunction


function! s:input_motion()
	let motion = ""
	while 1
		redraw
		echo motion
		let char = s:getchar()
		let motion .= char
		if char == "\<Esc>"
			return ""
		endif
		if s:has_motion(motion)
			break
		endif
	endwhile
	return motion
endfunction



function! s:blockwise(textobj, key, operator)
	let cnt = v:count > 0 ? v:count : ''
	let textobj = cnt . a:textobj

	let region = s:region(textobj)
	if empty(region)
		return
	endif
	let [topleft, bottomright] = region
	let pos = getpos(".")
	try
		while !empty(region)
\		   && region[1][1] >= topleft[1]
\		   && len(getline("."))
" \		   && region[1][1] == bottomright[1]
" 			echom getline(".")
			let bottomright = region[1]
			let col = col(".")
" 			echom a:operator . a:textobj
			execute "normal" a:operator . a:textobj
			silent execute "normal!" a:key
			call cursor(line("."), col)
			
			let region = s:region(textobj)
			if empty(region) || region[0][0] == bottomright[0]
				break
			endif
		endwhile
	finally
		call cursor(pos[1], pos[2])
	endtry
	return ["\<C-v>", s:as_cursorpos(topleft), s:as_cursorpos(bottomright)]
endfunction



function! s:blockwise_yank(motion, ...)
	let operator = get(a:, 1, "y")
	let g:yank = ""
	let g:operator#blockwise#yank = ""
	let register = v:register == "" ? '"' : v:register
	let result = s:blockwise(a:motion, "j:let g:operator#blockwise#yank .= @\" . \"\\n\"\<CR>", operator)
	call setreg(register, g:operator#blockwise#yank, "b")
	return result
endfunction
"
"
" function! s:blockwise_delete(motion)
" 	return s:blockwise_yank(a:motion, "d")
" endfunction


function! s:operator_blockwise(operator, motion)
	if a:operator ==# "y"
		return s:blockwise_yank(a:motion, "y")
	elseif a:operator ==# "d"
		return s:blockwise_yank(a:motion, "d")
	elseif a:operator ==# "c"
		let result = s:blockwise_yank(a:motion, "d")
		if type(result) == type(0)
			return result
		endif
		let size = result[2][1] - result[1][1]
		call feedkeys("\<C-v>" . size . "jI")
		return result
	else
		return s:blockwise(a:motion, "j", a:operator)
	endif
endfunction


function! operator#blockwise#operator(operator)
	let motion = s:input_motion()
	if motion == ""
		return
	endif
	let result = s:operator_blockwise(a:operator, motion)
	call cursor(result[1][1], result[1][2])
	return result
endfunction


function! operator#blockwise#mapexpr(operator)
" 	return ":call operator#blockwise#operator(" . string(a:operator) . ")\<CR>"
	let g:operator#blockwise#operator = a:operator
	return ":call operator#blockwise#operator(g:operator#blockwise#operator)\<CR>"
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
