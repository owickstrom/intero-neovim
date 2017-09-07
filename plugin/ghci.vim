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
" Gets the type at the current point or in visual selection
command! -nargs=0 -bang -range GhciType call ghci#repl#type(visualmode())
" Gets info for the identifier at the current point
command! -nargs=0 -bang GhciInfo call ghci#repl#info()
" Reload
command! -nargs=0 -bang GhciReload call ghci#repl#reload()
" Kill and restart the GHCi process
command! -nargs=0 -bang GhciRestart call ghci#process#restart()

if g:ghci_use_neomake
    " Neomake integration
    let g:neomake_ghci_maker = {
            \ 'exe': 'cat',
            \ 'args': [ghci#maker#get_log_file()],
            \ 'errorformat':
                \ '%-G%\s%#,' .
                \ '%f:%l:%c:%trror: %m,' .
                \ '%f:%l:%c:%tarning: %m,'.
                \ '%f:%l:%c: %trror: %m,' .
                \ '%f:%l:%c: %tarning: %m,' .
                \ '%E%f:%l:%c:%m,' .
                \ '%E%f:%l:%c:,' .
                \ '%Z%m'
        \ }
endif

" Store the path to the plugin directory, so we can lazily load the Python module
let g:ghci_plugin_root = expand('<sfile>:p:h:h')

" vim: set ts=4 sw=4 et fdm=marker:
