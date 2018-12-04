scriptencoding utf-8
function cmpfind#filename_to_pathname(filename)
    let l:cond = printf("find . -type f -name %s", a:filename)
    let l:filepath = system(l:cond)
	echo a:filename
    "execute 'edit' l:filepath
endfunction

function cmpfind#complete_filename(lead, line, pos)
    if 0 == len(a:lead)
        let l:search_cond = "find . -type f"
    else
        let l:search_cond = printf("find . -type f -iname \"*%s*\" | grep -v \"swp\"", a:lead)
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

