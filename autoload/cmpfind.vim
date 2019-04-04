scriptencoding utf-8

let s:mode_current = "current"
let s:mode_tab = "tab"
let s:switch_mode = s:mode_current
let s:found_file_list = []
let s:found_grep_list = []
let s:found_tag_list = []
let s:crt_cursor = 1
let s:win_name = "cmpfind_win"
let s:win_bufnr = 0
let s:match_num = 0

function cmpfind#filename_to_pathname(filename,mode)
	let s:switch_mode = a:mode
    let l:cond = printf("find . -type f -name \"%s\"", a:filename)
    let l:filepath = system(l:cond)
	if 1 == len(split(l:filepath))
		call cmpfind#switch_buffer(l:filepath)
	else
		let l:cond = printf("find . -type f -iname \"*%s*\" | grep -v \".swp\"", a:filename)
		let l:filepath = system(l:cond)
		if 1 == len(split(l:filepath))
			call cmpfind#switch_buffer(l:filepath)
		else
			call cmpfind#force_complete_mode(a:filename)
		endif
	endif
endfunction

function cmpfind#force_complete_mode(filename)
	if s:switch_mode == s:mode_current
		call feedkeys(":E ".a:filename."\t", 't')
	else
		call feedkeys(":ET ".a:filename."\t", 't')
	endif
endfunction

function cmpfind#switch_buffer(filepath)
	if s:switch_mode == s:mode_current
		execute 'edit' a:filepath
	else
		execute 'tabnew' a:filepath
	endif
endfunction

function cmpfind#complete_filename(lead, line, pos)
    if 0 == len(a:lead)
        let l:search_cond = "find . -type f"
    else
        let l:search_cond = printf("find . -type f -iname \"*%s*\" | grep -v \".swp\"", a:lead)
    endif
    echomsg l:search_cond
    let l:search_result = system(l:search_cond)
    let l:comp_fullpath_list = split(l:search_result, '\n')
    let l:comp_list = []
    for v in l:comp_fullpath_list
        let l:arr = split(v,'/')
        call add(l:comp_list, l:arr[len(l:arr)-1])
    endfor
    return l:comp_list
endfunction

function cmpfind#complete_revision(lead, line, pos)
	let l:cond = printf("svn log %s | grep -o \"^r[0-9]\\+\"", expand('%:p'))
	let l:revs = system(l:cond)
	let l:arr = []
	let l:arr = split(l:revs, '\n')
	return l:arr
endfunction

function cmpfind#open_specific_rev(rev)
	let l:extension = expand('%:e')
	execute "diffthis"
	let l:cond = printf("svn cat -r %s %s", a:rev, expand('%:p'))
	execute "vnew"
	execute "%!".l:cond
	execute "setl ft=".l:extension
	execute "diffthis"
	setl nomodifiable
endfunction

function cmpfind#input_filename(filename)
	echomsg a:filename
	augroup cmpfind
		autocmd!
		autocmd CursorMovedI * call cmpfind#input_filename(getline('.'))
	augroup END
endfunction

function cmpfind#dejizo_get_cb(handle, msg)
	let l:xml_str = substitute(a:msg, ".*<GetDicItemResult", "<GetDicItemResult", "")
	let l:html_body = substitute(l:xml_str, ".*Body>\\(.*\\)</Body>.*", "\\1", "")
	let l:trans_ret = substitute(l:html_body, ".*<div>\\(.*\\)</div>.*</div>.*", "\\1", "")
	echomsg l:trans_ret
	execute "messages"
endfunction

function cmpfind#dejizo_search_cb(handle, msg)
	let l:xml_str = substitute(a:msg, ".*<SearchDicItemResult", "<SearchDicItemResult", "")
	let l:item_id = substitute(l:xml_str, ".*ItemID>\\([0-9]\\+\\)</ItemID.*", "\\1", "")
	if match(l:item_id, "[a-z]") >= 0
		echohl Error | echo "Not found" | echohl None
	else
		let s:handle = ch_open("public.dejizo.jp:80", {"mode":"raw", "waittime":"100"})
		if ch_status(s:handle) == "open"
			call ch_sendraw(s:handle, "GET /NetDicV09.asmx/GetDicItemLite?Dic=EJdict&Item=".l:item_id."&Loc=&Prof=XHTML HTTP/1.0\r\n\r\n", {"callback":"cmpfind#dejizo_get_cb"})
		endif
	endif
endfunction

function cmpfind#trans_under_cursor(search_word)
	let s:handle = ch_open("public.dejizo.jp:80", {"mode":"raw", "waittime":"100"})
	if ch_status(s:handle) == "open"
		echo "ch opend"
		"call ch_logfile("ch_log.txt","a")
		call ch_sendraw(s:handle, "GET /NetDicV09.asmx/SearchDicItemLite?Dic=EJdict&Word=".a:search_word."&Scope=HEADWORD&Match=STARTWITH&Merge=OR&Prof=XHTML&PageSize=1&PageIndex=0 HTTP/1.0\r\n\r\n", {"callback":"cmpfind#dejizo_search_cb"})
	else
		echo "ch closed"
	endif
endfunction

function cmpfind#aaa()
	call setline(1,"JJJ")
endfunction

function cmpfind#inc_search()

	echohl Identifier | echo "file:<f>" | echohl Define | echo "grep:<g>" | echohl Label | echo "tags:<t>" | echohl None
	let l:mode = nr2char(getchar())
	if l:mode == 'f'
	elseif l:mode == 'g'
	elseif l:mode == 't'
	else
		redraw
		return
	endif

	nunmap <c-p>
	execute "keepalt botright 10new ".s:win_name
	let s:win_bufnr = bufnr(s:win_name)
	let g:prompt = "> "
	let l:keyloop = 1
	let l:inc_word = ""
	execute "nnoremap <silent> <C-n> :call cmpfind#aaa()<CR>"
	let s:crt_cursor = 1

	if l:mode == 'f'
		call cmpfind#background_find_file()
	endif

	while l:keyloop
		redraw
		echo g:prompt.l:inc_word
		let l:char = getchar()

		"let l:cmd = matchstr(maparg("<C-n>"), ':\zs.\+\ze<CR>$')

		"printable character
		if ((0x20<=l:char) && (l:char<=0x7a)) || (l:char == "\<BS>")
			if l:char == "\<BS>"
				"delete last character from inc_word
				let l:inc_word = substitute(l:inc_word, ".$", "", "")
			endif
			let l:inc_word = l:inc_word . nr2char(l:char)

			if l:inc_word == ''
				continue
			endif

			if l:mode == 'f'
				let s:match_num = cmpfind#listup_file(l:inc_word)
			elseif l:mode == 'g'
				let s:match_num = cmpfind#listup_grep(l:inc_word)
			elseif l:mode == 't'
				let s:match_num = cmpfind#listup_tags(l:inc_word)
			endif
			call cmpfind#adjust_height(s:match_num)
		"go to next line
		elseif l:char == 0x09
			let s:crt_cursor = s:crt_cursor + 1
			call cursor(s:crt_cursor,1)
		"decide keyword
		elseif l:char == 0x0d
			let l:keyloop = 0
			let l:crt_line_str = getline(s:crt_cursor)
			call cmpfind#clean()
			if s:match_num != 0
				if l:mode == 'f'
					execute "edit ".l:crt_line_str
				elseif l:mode == 'g'
					let l:edit_filename = matchstr(l:crt_line_str, '^[^:]\+')
					let l:line_number = matchstr(l:crt_line_str, '\zs[0-9]\+\ze:')
					execute 'edit +'.l:line_number." ".l:edit_filename
				elseif l:mode == 't'
					let l:tag_param = split(l:crt_line_str, '[\t]\+')
					execute 'edit '.l:tag_param[1]
					execute escape(l:tag_param[2],"*[]")
					redraw
					:noh
				else
				endif
			endif
		"cancel
		elseif l:char == 0x1b
			let l:keyloop = 0
			call cmpfind#clean()
		elseif l:char == "<C-n>"
			execute "bdelete!" l:list_buf
			
		"control character
		else
			execute 'normal '.l:char
		endif
	endwhile
endfunction

function cmpfind#listup_file(word)
	execute "%d"
	let l:line_idx = 1
	let s:found_file_list = []

	let l:path_list = split(g:cmpfind_search_path,',')
	for path in l:path_list
		let l:cond = printf("find %s -type f -iname \"*%s*\"",l:path,a:word)
		let l:find_ret = system(l:cond)
		let s:found_file_list += split(l:find_ret, '\n')
	endfor

	if len(s:found_file_list) == 0
		call cmpfind#err_msg("No matched entry")
	else
		for v in s:found_file_list
			if l:v =~? a:word
				call setline(l:line_idx, l:v)
				let l:line_idx = l:line_idx + 1
			endif
		endfor
		call cmpfind#highlight_in_list(a:word)
	endif
	return l:line_idx-1
endfunction

function cmpfind#listup_grep(word)
	execute "%d"
	let l:line_idx = 1
	let l:match_num = system("grep -ri ".a:word." . | wc -l")

	if l:match_num > 300
		call cmpfind#err_msg("Result is too many")
	elseif l:match_num == 0
		call cmpfind#err_msg("No matched entry")
	else
		for v in split(system("grep -Hnri ".a:word." ."), '\n')
			call setline(l:line_idx, l:v)
			let l:line_idx = l:line_idx + 1
		endfor
		call cmpfind#highlight_in_list(a:word)
	endif
	return l:line_idx-1
endfunction

function cmpfind#listup_tags(word)
	execute "%d"
	let l:line_idx = 1
	let s:found_tag_list = []

	"let l:tag_list = split(&tags, ',')
	let l:tag_list = split(g:cmpfind_search_tags, ',')
	for v in l:tag_list
		let l:cond = "grep -i ^".a:word." ".l:v
		let l:find_ret = system(l:cond)
		let s:found_tag_list += split(l:find_ret, '\n')
	endfor

	if len(s:found_tag_list) == 0
		call cmpfind#no_match("No matched entry")
	else
		for v in s:found_tag_list
			if l:v =~? "^".a:word
				call setline(l:line_idx, l:v)	
				let l:line_idx = l:line_idx + 1
			endif
		endfor
		call cmpfind#highlight_in_list(a:word)
	endif
	"return l:line_idx-1
	return len(s:found_tag_list)
endfunction

function cmpfind#err_msg(msg)
	call setline(1,a:msg)
	execute 'match Error /.*/'
endfunction

function cmpfind#highlight_in_list(word)
	execute 'match SignColumn /'. escape(a:word,'/') .'\c/'
endfunction

function cmpfind#adjust_height(match_num)
	if a:match_num == 0
		execute 'resize 1'
	elseif a:match_num < 10
		execute 'resize '.a:match_num
	else
		execute 'resize 10'
	endif
endfunction

function cmpfind#background_find_file()
	let l:path_list = split(g:cmpfind_search_path,',')
	for path in l:path_list
		let l:cond = printf("find %s -type f ",l:path)
		let l:find_ret = system(l:cond)
		let s:found_file_list += split(l:find_ret, '\n')
	endfor
endfunction

function cmpfind#clean()
	execute "%d"
	let s:found_file_list = []
	let s:crt_cursor = 1

	execute "bdelete!" s:win_bufnr
	execute "nnoremap <silent> ".g:cmpfind_inc_map." :call cmpfind#inc_search()<CR>"
endfunction
