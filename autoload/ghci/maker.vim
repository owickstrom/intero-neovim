""""""""""
" Maker:
"
" This file contains code for integrating with Neomake.
""""""""""

" This is where we store the build log for consumption by Neomake.
let s:log_file = tempname()

function! ghci#maker#get_log_file() abort
    " Getter for log file path

    return s:log_file
endfunction

function! ghci#maker#write_update(lines) abort
    " Writes the specified lines to the log file, then notifies Neomake

    call writefile(a:lines, s:log_file)

    if g:ghci_use_neomake && exists(':NeomakeProject')
        NeomakeProject ghci
    endif
endfunction

function! ghci#maker#cleanup() abort
    call system('rm -f ' . s:log_file)
endfunction

