if exists('g:did_plugin_ghci') && g:did_plugin_ghci
    finish
endif
let g:did_plugin_ghci = 1

if !exists('g:ghci_use_neomake')
    let g:ghci_use_neomake = 1
endif

" Starts the GHCi process in the background.
command! -nargs=0 -bang GhciStart call ghci#process#start()
" Kills the GHCi process.
command! -nargs=0 -bang GhciKill call ghci#process#kill()
" Opens the ghci buffer.
command! -nargs=0 -bang GhciOpen call ghci#process#open()
" Hides the ghci buffer.
command! -nargs=0 -bang GhciHide call ghci#process#hide()
" Loads the current module in ghci.
command! -nargs=0 -bang GhciLoadCurrentModule call ghci#repl#load_current_module()
" Loads the current file in ghci.
command! -nargs=0 -bang GhciLoadCurrentFile call ghci#repl#load_current_file()
" Prompts user for a string to eval
command! -nargs=? -bang GhciEval call ghci#repl#eval(<f-args>)

noremap <expr> <Plug>GhciType ghci#repl#pos_for_type()
command! -nargs=* -bang -range GhciTypeAt call ghci#repl#type(<f-args>)

" Gets info for the identifier at the current point
command! -nargs=0 -bang GhciInfo call ghci#repl#info()
" Inserts type signature for identifier at the current point
command! -nargs=0 -bang GhciTypeInsert call ghci#repl#insert_type()
" Reload
command! -nargs=0 -bang GhciReload call ghci#repl#reload()
" Kill and restart the GHCi process
command! -nargs=0 -bang GhciRestart call ghci#process#restart()

if g:ghci_use_neomake
    " Neomake integration

    " Try GHC 8 errors and warnings, then GHC 7 errors and warnings, and regard
    " lines starting with two spaces as continuations on an error message. All
    " other lines are disregarded. This gives a clean one-line-per-entry in the
    " QuickFix list.
    let s:efm = '%E%f:%l:%c:\ error:%#,' .
                \ '%W%f:%l:%c:\ warning:%#,' .
                \ '%W%f:%l:%c:\ warning:\ [-W%.%#]%#,' .
                \ '%f:%l:%c:\ %trror: %m,' .
                \ '%f:%l:%c:\ %tarning: %m,' .
                \ '%E%f:%l:%c:%#,' .
                \ '%E%f:%l:%c:%m,' .
                \ '%W%f:%l:%c:\ Warning:%#,' .
                \ '%C\ \ %m%#,' .
                \ '%-G%.%#'

    let g:neomake_ghci_maker = {
            \ 'exe': 'cat',
            \ 'args': [ghci#maker#get_log_file()],
            \ 'errorformat': s:efm
        \ }
endif

" Store the path to the plugin directory, so we can lazily load the Python module
let g:ghci_plugin_root = expand('<sfile>:p:h:h')

" vim: set ts=4 sw=4 et fdm=marker:
