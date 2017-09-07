""""""""""
" Repl:
"
" This file contains code for sending commands to the GHCi REPL.
""""""""""

let s:starting_up_msg = 'GHCi is still starting up...'

function! ghci#repl#eval(...) abort
    if !g:ghci_started
        echoerr starting_up_msg
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
        echoerr starting_up_msg
    else
        " Loads the current module, inferred from the given filename.
        call ghci#repl#send(':l ' . ghci#loc#detect_module())
    endif
endfunction

function! ghci#repl#load_current_file() abort
    if !g:ghci_started
        echoerr starting_up_msg
    else
        " Load the current file
        call ghci#repl#send(':l ' . expand('%:p'))
    endif
endfunction

" the `visual` argument should be either '' or 'V'
function! ghci#repl#type(visual) abort
    if (a:visual == 'V')
        let l:expr = ghci#util#get_visual_selection()
    else
        let l:expr = ghci#util#get_haskell_identifier()
    endif

    call ghci#repl#eval(':type ' . l:expr)
endfunction

function! ghci#repl#info() abort
    if !g:ghci_started
        echoerr starting_up_msg
    else
        let l:ident = ghci#util#get_haskell_identifier()
        call ghci#repl#eval(':info ' . l:ident)
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
        echoerr starting_up_msg
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
    let l:message = join(a:lines, '\n')
    if l:message =~# ' :: '
        call append(line('.')-1, a:lines)
    else
        echomsg l:message
    end
endfunction

