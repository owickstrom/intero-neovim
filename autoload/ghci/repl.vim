""""""""""
" Repl:
"
" This file contains code for sending commands to the GHCi REPL.
""""""""""

let s:starting_up_msg = 'GHCi is still starting up...'

" The indent level (number of spaces) of the identifier to insert a type for.
" It's inserted in a callback, hence this state variable.
let s:insert_type_indent = 0

function! ghci#repl#eval(...) abort
    if !g:ghci_started
        echoerr s:starting_up_msg
    else
        " Given no arguments, this requests an expression from the user and
        " evaluates it in the GHCi REPL.
        if a:0 == 0
            call inputsave()
            let l:eval = input('Command: ')
            call inputrestore()
        elseif a:0 == 1
            let l:eval = a:1
        else
            echomsg 'Call with nothing for eval or with command string.'
            return
        endif

        let g:ghci_echo_next = 1
        call ghci#repl#send(l:eval)
    endif
endfunction

function! ghci#repl#load_current_module() abort
    if !g:ghci_started
        echoerr s:starting_up_msg
    else
        " Loads the current module, inferred from the given filename.
        call ghci#repl#send(':l ' . ghci#loc#detect_module())
    endif
endfunction

function! ghci#repl#load_current_file() abort
    if !g:ghci_started
        echoerr s:starting_up_msg
    else
        " Load the current file
        call ghci#repl#send(':l ' . expand('%:p'))
    endif
endfunction

" Called only if the version of GHCi doesn't support :type-at.
function! s:type(l1, c1, l2, c2) abort
    if !(a:l1 == a:l2 && a:c1 == a:c2)
        let l:expr = ghci#util#get_visual_selection()
    else
        let l:expr = ghci#util#get_haskell_identifier()
    endif

    call ghci#repl#eval(':type ' . l:expr)
endfunction

function! s:get_module_filepath() abort
    if g:ghci_command =~# "^stack"
        return expand('%:p')
    else
        return @%
    endif
endfunction

" Called only if the version of GHCi supports :type-at.
function! s:type_at(l1, c1, l2, c2) abort
    let l:module = s:get_module_filepath()

    if !(a:l1 == a:l2 && a:c1 == a:c2)
        let l:identifier = ghci#util#get_selection(a:l1, a:c1, a:l2, a:c2)
        let l:col1 = a:c1
        let l:col2 = a:c2
    else
        let [l:identifier, l:col1, l:col2] = ghci#util#get_haskell_identifier_and_pos()
    endif

    call ghci#repl#eval(
        \ join([':type-at', '"' . l:module . '"', a:l1, l:col1, a:l2, l:col2 + 1, l:identifier], ' '))
endfunction

function! s:supports_type_at() abort
    let [l:major, l:minor, l:patch] = g:ghci_version
    " >= 8.0.1 supports :type-at
    return l:major >= 8 && ((l:minor == 0 && l:patch >= 1) || l:minor > 0)
endfunction

" The entry point for getting type information, checking what the GHCi REPL
" supports.
function! ghci#repl#type(l1, c1, l2, c2) abort
    if s:supports_type_at()
        call s:type_at(a:l1, a:c1, a:l2, a:c2)
    else
        call s:type(a:l1, a:c1, a:l2, a:c2)
    endif
endfunction

" This function gets the type of what's under the cursor OR under a selection.
" It MUST be run from a key mapping (commands exit you out of visual mode).
function! ghci#repl#pos_for_type() abort
    " 'v' gets the start of the selection (or cursor pos if no selection)
    let [l:l1, l:c1] = getpos('v')[1:2]
    " " '.' gets the cursor pos (or the end of the selection if selection)
    let [l:l2, l:c2] = getpos('.')[1:2]

    " Meant to be used from an expr map (:help :map-<expr>).
    " That means we have to return the next command as a string.
    return ':GhciTypeAt '.l:l1.' '.l:c1.' '.l:l2.' '.l:c2."\<CR>"
endfunction

function! ghci#repl#info() abort
    if !g:ghci_started
        echoerr s:starting_up_msg
    else
        let l:ident = ghci#util#get_haskell_identifier()
        call ghci#repl#eval(':info ' . l:ident)
    endif
endfunction

function! ghci#repl#insert_type() abort
    if !g:ghci_started
        echoerr 'GHCi is still starting up.'
    else
        let [l:identifier, l:c1, l:c2] = ghci#util#get_haskell_identifier_and_pos()
        " for callback to add correct indent:
        let s:insert_type_indent = l:c1

        if s:supports_type_at()
            let l:l = line('.')
            let l:module = s:get_module_filepath()
            let l:cmd = join([':type-at', '"' . l:module . '"', l:l, l:c1, l:l, l:c2 + 1, l:identifier], ' ')
        else
            let l:cmd = join([':type', l:identifier], ' ')
        endif

        call ghci#process#add_handler(function('s:paste_type'))
        call ghci#repl#send(l:cmd)
    endif
endfunction

function! ghci#repl#send(str) abort
    " Sends a:str to the GHCi REPL.
    if !exists('g:ghci_buffer_id')
        echomsg 'GHCi not running.'
        return
    endif
    call jobsend(g:ghci_job_id, add([a:str], ''))
endfunction

function! ghci#repl#reload() abort
    if !g:ghci_started
        echoerr s:starting_up_msg
    else
        " Truncate file, so that we don't show stale results while recompiling
        call ghci#maker#write_update([])

        call ghci#repl#send(':reload')
    endif
endfunction

""""""""""
" Private:
""""""""""

function! s:paste_type(lines) abort
    let l:indent = repeat(' ', s:insert_type_indent)

    let l:first = a:lines[0]
    " We indent all but the first line.
    let l:indented = []
    for l:line in a:lines[1:]
        call add(l:indented, l:indent . l:line)
    endfor

    let l:old = getline('.')

    if s:insert_type_indent > 0
        let l:prefix = l:old[0:(s:insert_type_indent - 1)]
        let l:suffix = l:old[(s:insert_type_indent):]
    else
        let l:prefix = ''
        let l:suffix = l:old
    endif

    let l:message = join(a:lines, '\n')
    if l:message =~# ' :: '
        call setline(line ('.'), l:prefix . l:first)
        call append(line ('.'), l:indented + [l:indent . l:suffix])
    else
        echomsg l:message
    end
endfunction
