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

    let l:valid_target_dict = {}
    " we are in a stack project, and there are desired targets. validate that
    " they are contained inside the stack load targets
    for l:target in a:targets
        if index(l:stack_targets, l:target) == -1
            " Interpret this as a regex and add all matching targets to the
            " list.
            let l:matches = filter(copy(l:stack_targets), 'v:val =~ l:target')
            for l:match in l:matches
                let l:valid_target_dict[l:match] = 1
            endfor
        else 
            let l:valid_target_dict[l:target] = 1
        endif
    endfor

    let g:intero_load_targets = keys(l:valid_target_dict)
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

