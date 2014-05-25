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



" a <= b
function! s:pos_less_equal(a, b)
	return a:a[0] == a:b[0] ? a:a[1] <= a:b[1] : a:a[0] <= a:b[0]
endfunction


function! s:as_config(config)
	let default = {
\		"textobj" : "",
\		"is_cursor_in" : 0,
\		"noremap" : 0,
\	}
	let config
\		= type(a:config) == type("") ? { "textobj" : a:config }
\		: type(a:config) == type({}) ? a:config
\		: {}
	return extend(default, config)
endfunction


let s:region = []
let s:wise = ""
function! operator#blockwise#region_operator(wise)
	let reg_save = @@
	let s:wise = a:wise
	let s:region = [getpos("'[")[1:], getpos("']")[1:]]
	let @@ = reg_save
endfunction

nnoremap <silent> <Plug>(operator-blockwise-region-operator)
\	:<C-u>set operatorfunc=operator#blockwise#region_operator<CR>g@


function! operator#blockwise#region_from_textobj(textobj)
	let s:region = []
	let config = s:as_config(a:textobj)

	let pos = getpos(".")
	try
		silent execute (config.noremap ? 'onoremap' : 'omap') '<expr>'
\			'<Plug>(operator-blockwise-target)' string(config.textobj)

		let tmp = &operatorfunc
		silent execute "normal \<Plug>(operator-blockwise-region-operator)\<Plug>(operator-blockwise-target)"
		let &operatorfunc = tmp

		if !empty(s:region) && !s:pos_less_equal(s:region[0], s:region[1])
			return ["", []]
		endif
		if !empty(s:region) && config.is_cursor_in && (s:pos_less(pos[1:], s:region[0]) || s:pos_less(s:region[1], pos[1:]))
			return ["", []]
		endif
		return deepcopy([s:wise, s:region])
	finally
		call setpos(".", pos)
	endtry
endfunction


function! s:has_motion(name)
	return s:mapcheck_once(a:name, "o") || !empty(operator#blockwise#region_from_textobj(a:name)[1])
endfunction


function! s:getchar()
	let char = getchar()
	return type(char) == type(0) ? nr2char(char) : char
endfunction


function! s:input_motion()
	let motion = ""
	while 1
		redraw
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


function! s:through(...)
	return 1
endfunction


function! s:blockwise(textobj, key, operator, ...)
	let cnt = v:count > 0 ? v:count : ''
	let textobj = cnt . a:textobj
	let Comp = get(a:, 1, function("s:through"))

	let region = s:region(textobj)
	if empty(region)
		return
	endif
	let [topleft, bottomright] = region
	let pos = getpos(".")
	try
		while !empty(region)
\		   && len(getline("."))
\		   && region[1][1] >= topleft[1]
\		   && Comp(region, topleft, bottomright)
			let bottomright = region[1]
			let col = col(".")

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
	let Comp = get(a:, 2, function("s:through"))
	let g:yank = ""
	let g:operator#blockwise#yank = ""
	let register = v:register == "" ? '"' : v:register
	let result = s:blockwise(a:motion, "j:let g:operator#blockwise#yank .= @\" . \"\\n\"\<CR>", operator, Comp)
	call setreg(register, g:operator#blockwise#yank, "b")
	return result
endfunction


function! s:operator_blockwise(operator, motion, comp)
	if a:operator ==# "y"
		return s:blockwise_yank(a:motion, "y", a:comp)
	elseif a:operator ==# "d"
		return s:blockwise_yank(a:motion, "d", a:comp)
	elseif a:operator ==# "c"
		let result = s:blockwise_yank(a:motion, "d", a:comp)
		if type(result) == type(0)
			return result
		endif
		let size = result[2][1] - result[1][1]
		call feedkeys("\<C-v>" . size . "jI")
		return result
	else
		return s:blockwise(a:motion, "j", a:operator, a:comp)
	endif
endfunction


function! operator#blockwise#operator(operator, ...)
	let motion = s:input_motion()
	if motion == ""
		return
	endif
	let Comp = get(a:, 1, function("s:through"))
	let result = s:operator_blockwise(a:operator, motion, Comp)
	call cursor(result[1][1], result[1][2])
	return result
endfunction


function! operator#blockwise#mapexpr(operator, ...)
" 	return ":call operator#blockwise#operator(" . string(a:operator) . ")\<CR>"
	let g:operator#blockwise#operator = a:operator
	let g:OperatorBlockwiseCompFunc = get(a:, 1, function("s:through"))
	return ":\<C-u>call operator#blockwise#operator(g:operator#blockwise#operator, g:OperatorBlockwiseCompFunc)\<CR>"
endfunction


function! s:head_match(region, topleft, bottomright)
	return a:region[0][1] == a:topleft[1]
endfunction


function! operator#blockwise#mapexpr_head(operator, ...)
	return operator#blockwise#mapexpr(a:operator, function("s:head_match"))
endfunction


function! s:tail_match(region, topleft, bottomright)
	return a:region[1][1] == a:bottomright[1]
endfunction


function! operator#blockwise#mapexpr_tail(operator, ...)
	return operator#blockwise#mapexpr(a:operator, function("s:tail_match"))
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
