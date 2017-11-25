<div align="center">
  <h1>neovim-ghci</h1>
  <p>Interactive Haskell development using GHCi in Neovim</p>
</div>
<hr>

This is a fork of [intero-neovim][] that uses regular GHCi, instead of
`intero`. It has fewer features than its Intero counterpart, but does not rely
on Stack and Intero.

Some key features:

- **On-the-fly Typechecking**

  This plugin reports errors and warnings as you work on your file using the
  Neomake plugin. Errors appear asynchronously, and don't block the UI.

- **Built-in REPL**

  Work with your Haskell code directly in GHCi using Neovim `:terminal` buffers.
  Load your file and play around with top-level functions directly.

- **Type Information**

  You can ask for type information of the identifier under your cursor as well
  as of a selection.

## Demo

[![asciicast](https://asciinema.org/a/q9I5eNblDLCoOiQlZjm1ce0ba.png)](https://asciinema.org/a/q9I5eNblDLCoOiQlZjm1ce0ba?size=20&speed=3&theme=tango)

## Installing

This plugin is compatible with `pathogen`, `vim-plug`, etc. For example:

```viml
Plug 'owickstrom/neovim-ghci'
```

This plugin requires [Cabal][], 1.24.0 or higher. Optionally, install
[Neomake][] for error reporting.


## Quickstart

- To open the REPL:
  - `:GhciOpen`
- To load into the REPL:
  - `:GhciLoadCurrentFile`
- To reload whatever's in the REPL:
  - `:GhciReload`
- To evaluate an expression from outside the REPL:
  - `:GhciEvaluate <expression>`, or
  - `:GhciEvaluate`, and then enter the expression in the prompt.

## Usage

Complete usage and configuration information can be found in here:

```vim
:help ghci
```

## Example Configuration

These are some suggested settings. This plugin sets up no keybindings by
default.

```vim
augroup ghciMaps
  au!
  " Maps for ghci. Restrict to Haskell buffers so the bindings don't collide.

  " Background process and window management
  au FileType haskell nnoremap <silent> <leader>gs :GhciStart<CR>
  au FileType haskell nnoremap <silent> <leader>gk :GhciKill<CR>

  " Restarting GHCi might be required if you add new dependencies
  au FileType haskell nnoremap <silent> <leader>gr :GhciRestart<CR>

  " Open GHCi split horizontally
  au FileType haskell nnoremap <silent> <leader>go :GhciOpen<CR>
  " Open GHCi split vertically
  au FileType haskell nnoremap <silent> <leader>gov :GhciOpen<CR><C-W>H
  au FileType haskell nnoremap <silent> <leader>gh :GhciHide<CR>

  " Getting type information
  au FileType haskell map <silent> <leader>gt <Plug>GhciType

  " RELOADING (PICK ONE):

  " Automatically reload on save
  au BufWritePost *.hs GhciReload
  " Manually save and reload
  au FileType haskell nnoremap <silent> <leader>wr :w \| :GhciReload<CR>

  " Load individual modules
  au FileType haskell nnoremap <silent> <leader>gl :GhciLoadCurrentModule<CR>
  au FileType haskell nnoremap <silent> <leader>gf :GhciLoadCurrentFile<CR>
augroup END

" GHCi starts automatically. Set this if you'd like to prevent that.
let g:ghci_start_immediately = 0

" Customize how to run GHCi
let g:ghci_command = 'cabal new-repl'
let g:ghci_command_line_options = ''
```

### Using the Stack REPL

If you'd like to use `stack repl`, instead of plain `ghci` or `cabal repl`, you
can use something like the following configuration:

``` vim
let g:ghci_command = 'stack repl'
let g:ghci_command_line_options = '--ghci-options="-fobject-code"'
```

Using a [project specific
.nvim.rc](https://andrew.stwrt.ca/posts/project-specific-vimrc/), you can also
customize the Stack targets for the GHCi session of particular projects:

``` vim
let g:ghci_command = 'stack repl my-project:test:my-test-suite'
```

## Caveats

- Running `:Neomake!` directly will not work. You need to run `:GhciReload`
  instead.

- Some commands may have unexpected side-effects if you have an autocommand
  that automatically switches to insert mode when entering a terminal buffer.

## Contributing

This project welcomes new contributions! Submit pull requests and open issues
on GitHub: https://github.com/owickstrom/neovim-ghci

## License

[BSD3 License](http://www.opensource.org/licenses/BSD-3-Clause), the same
license as ghcmod-vim and [intero-neovim][].

[intero-neovim]: https://github.com/parsonsmatt/intero-neovim
[Cabal]: http://cabal.readthedocs.io/en/latest/
[Neomake]: https://github.com/neomake/neomake
