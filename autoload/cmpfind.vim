scriptencoding utf-8

let s:mode_current = "current"
let s:mode_tab = "tab"
let s:switch_mode = s:mode_current

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

function cmpfind#fuzzy_search()
	echo "fuzzy_search()"
endfunction
