"""""""""""
" Targets:
"
" This file contains functions for working with the Intero load targets. A
" target is something like a library, executable, benchmark, or test suite
" component of a Haskell package.
"""""""""""

if (!exists('g:intero_load_targets'))
    " A list of load targets.
    let g:intero_load_targets = []
endif

" Attempt to set the load targets. When passed an empty array, this uses the
" targets as given by `stack ide targets`.
function! intero#targets#set_load_targets(targets) abort
    if len(a:targets) == 0
        let g:intero_load_targets = s:load_targets_from_stack()
        return g:intero_load_targets
    endif

    " if stack targets are empty, then we are not in a stack project.
    " attempting to set the targets will cause the build command to fail.
    let l:stack_targets = s:load_targets_from_stack()
    if empty(l:stack_targets)
        let g:intero_load_targets = []
        return g:intero_load_targets
    endif

    let l:valid_targets = []
    " we are in a stack project, and there are desired targets. validate that
    " they are contained inside the stack load targets
    for l:target in a:targets
        if index(l:stack_targets, l:target) == -1
            call intero#util#print_warning('Target ' . l:target . ' not present in available Stack targets: ' . join(l:stack_targets, ' '))
        else 
            call add(l:valid_targets, l:target)
        endif
    endfor

    let g:intero_load_targets = l:valid_targets
    return g:intero_load_targets
endfunction

function! intero#targets#get_load_targets() abort
    return g:intero_load_targets
endfunction

function! intero#targets#load_targets_as_string() abort
    return join(intero#targets#get_load_targets(), ' ')
endfunction

function! intero#targets#load_targets_from_stack() abort
    return s:load_targets_from_stack()
endfunction

function! s:load_targets_from_stack() abort
    return systemlist('stack ide targets')
endfunction

" vim: set ts=4 sw=4 et fdm=marker:

