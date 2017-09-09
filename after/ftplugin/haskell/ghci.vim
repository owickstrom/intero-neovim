if exists('b:did_ftplugin_ghci') && b:did_ftplugin_ghci
    finish
endif
let b:did_ftplugin_ghci = 1

if !exists('g:ghci_start_immediately')
    let g:ghci_start_immediately = 1
endif

if !exists('g:ghci_command')
    let g:ghci_command = 'ghci'
endif

if g:ghci_start_immediately
    call ghci#process#start()
endif

if exists('b:undo_ftplugin')
    let b:undo_ftplugin .= ' | '
else
    let b:undo_ftplugin = ''
endif

let b:undo_ftplugin .= 'unlet b:did_ftplugin_ghci'

" vim: set ts=4 sw=4 et fdm=marker:
