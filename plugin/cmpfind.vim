scriptencoding utf-8
if exists('g:loaded_cmpfind')
	finish
endif

let g:loaded_cmpfind = 1
command! -nargs=1 -complete=customlist,cmpfind#complete_filename CmpFind call cmpfind#filename_to_pathname(<f-args>)
silent nnoremap <c-h> :CmpFind 
