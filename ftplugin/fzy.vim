vim9script
# ==============================================================================
# Run fzy asynchronously inside a Vim terminal-window
# File:         ftplugin/fzy.vim
# Author:       bfrg <https://github.com/bfrg>
# Website:      https://github.com/bfrg/vim-fzy
# Last Change:  Oct 21, 2022
# License:      Same as Vim itself (see :h license)
# ==============================================================================

tnoremap <silent> <buffer> <c-c> <c-w>:<c-u>call fzy#Stop()<cr>

b:undo_ftplugin = 'execute "tunmap <buffer> <c-c>"'
