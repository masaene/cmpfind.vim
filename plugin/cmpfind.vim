scriptencoding utf-8
if exists('g:loaded_cmpfind')
	finish
endif

let g:loaded_cmpfind = 1
command! -nargs=+ -complete=customlist,cmpfind#complete_filename E call cmpfind#filename_to_pathname(<f-args>,"current")
command! -nargs=+ -complete=customlist,cmpfind#complete_filename ET call cmpfind#filename_to_pathname(<f-args>,"tab")
command! -nargs=1 -complete=customlist,cmpfind#complete_revision SvnDiff call cmpfind#open_specific_rev(<f-args>)
nnoremap <silent> <c-h> gT
nnoremap <silent> <c-l> gt
"nnoremap <c-i> :call cmpfind#fuzzy_search()<CR>

"cnoremap <c-f> E 


