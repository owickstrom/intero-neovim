"""""""""""
" Process:
"
" This file contains functions for working with the GHCi process. This
" includes ensuring that GHCi is installed, starting/killing the
" process, and hiding/showing the REPL.
"""""""""""

" Lines of output consistuting of a command and the response to it
let s:current_response = []

" The current (incomplete) line
let s:current_line = ''

" Whether GHCi has finished starting yet
let g:ghci_started = 0

" Whether GHCi has done its initialization yet
let s:ghci_initialized = 0

" If true, echo the next response. Reset after each response.
let g:ghci_echo_next = 0

" Queue of functions to run when a response is received. For a given response,
" only the first will be run, after which it will be dropped from the queue.
let s:response_handlers = []

function! ghci#process#initialize() abort
    " This function initializes GHCi.

    " We only need to initialize once
    if s:ghci_initialized
        return
    endif

    if(!exists('g:ghci_built'))

        if g:ghci_use_neomake && !exists(':Neomake')
            echom 'Neomake not detected. Flychecking will be disabled.'
        endif

        " Load Python code
        py import sys
        call pyeval('sys.path.append("' . g:ghci_plugin_root . '")')
        py import ghci

        let g:ghci_built = 1
    endif

    let s:ghci_initialized = 1
endfunction

function! ghci#process#start() abort
    " This is the entry point. It ensures that GHCi is initialized, then
    " starts an ghci terminal buffer. Initially only occupies a small area.
    " Returns the ghci buffer id.

    call ghci#process#initialize()

    if(!exists('g:ghci_built') || g:ghci_built == 0)
        echom 'GHCi is still compiling'
        return -1
    endif

    if !exists('g:ghci_buffer_id')
        let g:ghci_buffer_id = s:start_buffer(10)
    endif

    augroup close_ghci
        autocmd!
        autocmd VimLeavePre * call ghci#process#kill()
        autocmd VimLeave * call ghci#maker#cleanup()
    augroup END

    return g:ghci_buffer_id
endfunction

function! ghci#process#kill() abort
    " Kills the ghci buffer, if it exists.
    if exists('g:ghci_buffer_id')
        exe 'bd! ' . g:ghci_buffer_id
        unlet g:ghci_buffer_id
        " Deleting a terminal buffer implicitly stops the job
        unlet g:ghci_job_id
        let g:ghci_started = 0
    endif
endfunction

function! ghci#process#hide() abort
    " Hides the current buffer without killing the process.
    silent! call s:hide_buffer()
endfunction

function! ghci#process#open() abort
    " Opens the GHCi REPL. If the REPL isn't currently running, then this
    " creates it. If the REPL is already running, this is a noop. Returns the
    " window ID.
    call ghci#process#initialize()

    let l:ghci_win = ghci#util#get_ghci_window()
    if l:ghci_win != -1
        return l:ghci_win
    elseif exists('g:ghci_buffer_id')
        let l:current_window = winnr()
        silent! call s:open_window(10)
        exe 'silent! buffer ' . g:ghci_buffer_id
        normal! G
        exe 'silent! ' . l:current_window . 'wincmd w'
    else
        let l:rc = ghci#process#start()
        if l:rc < 0
            return
        endif
        return ghci#process#open()
    endif
endfunction

function! ghci#process#add_handler(func) abort
    " Adds an event handler to the queue
    let s:response_handlers = s:response_handlers + [a:func]
endfunction

function! ghci#process#restart() abort
    call ghci#process#kill()
    call ghci#process#start()
endfunction

""""""""""
" Private:
""""""""""

function! s:start_buffer(height) abort
    " Starts an GHCi REPL in a split below the current buffer. Returns the
    " ID of the buffer.
    exe 'below ' . a:height . ' split'

    let l:invocation = 'new-repl'
    if exists('g:ghci_command_line_options')
      let l:invocation .= ' ' . g:ghci_command_line_options
    endif

    enew
    silent call termopen('cabal '
        \ . l:invocation, {
                \ 'on_stdout': function('s:on_stdout'),
                \ 'cwd': '.'
                \ })

    silent file GHCi
    set bufhidden=hide
    set noswapfile
    set hidden
    let l:buffer_id = bufnr('%')
    let g:ghci_job_id = b:terminal_job_id
    quit
    call feedkeys("\<ESC>")
    return l:buffer_id
endfunction

function! s:on_stdout(jobid, lines, event) abort
    if !exists('g:ghci_prompt_regex')
        let g:ghci_prompt_regex = '[^-]> '
    endif

    for l:line_seg in a:lines
        let s:current_line = s:current_line . l:line_seg

        " If we've found a newline, flush the line buffer
        if s:current_line =~# '\r$'
            " Remove trailing newline, control chars
            let s:current_line = substitute(s:current_line, '\r$', '', '')
            let s:current_line = pyeval('ghci.strip_control_chars("s:current_line")')

            " Flush line buffer
            let s:current_response = s:current_response + [s:current_line]
            let s:current_line = ''
        endif

        " If the current line is a prompt, we just completed a response.
        " Note that we need to strip control chars here, because otherwise
        " they're only removed when the line is added to the response.
        if pyeval('ghci.strip_control_chars("s:current_line")') =~ (g:ghci_prompt_regex . '$')
            if len(s:current_response) > 0
                " Separate the input command from the response
                let l:cmd = substitute(s:current_response[0], '.*' . g:ghci_prompt_regex, '', '')
                call s:new_response(l:cmd, s:current_response[1:])
            endif

            let s:current_response = []
        endif

    endfor
endfunction

function! s:new_response(cmd, response) abort
    let l:initial_compile = 0

    " This means that GHCi is now available to run commands
    if !g:ghci_started
        echom 'GHCi ready'
        let g:ghci_started = 1
        let l:initial_compile = 1
    endif

    " For debugging
    let g:ghci_response = a:response

    " These handlers are used for all events
    if g:ghci_echo_next
        echo join(a:response, "\n")
        let g:ghci_echo_next = 0
    endif

    if(l:initial_compile || a:cmd =~# ':reload')
        " Trigger Neomake's parsing of the compilation errors
        call ghci#maker#write_update(a:response)
    endif

    " If a handler has been registered, pop it and run it
    if len(s:response_handlers) > 0
        call s:response_handlers[0](a:response)
        let s:response_handlers = s:response_handlers[1:]
    endif
endfunction

function! s:open_window(height) abort
    " Opens a window of a:height and moves it to the very bottom.
    exe 'below ' . a:height . ' split'
    normal! <C-w>J
endfunction

function! s:hide_buffer() abort
    " This closes the GHCi REPL buffer without killing the process.
    if !s:ghci_initialized
        " GHCi was never started.
        return
    endif

    let l:window_number = ghci#util#get_ghci_window()
    if l:window_number > 0
        exec 'silent! ' . l:window_number . 'wincmd c'
    endif
endfunction
