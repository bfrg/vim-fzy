vim9script
# ==============================================================================
# Fuzzy-select files, buffers, args, tags, help tags, oldfiles, marks
# File:         plugin/fzy.vim
# Author:       bfrg <https://github.com/bfrg>
# Website:      https://github.com/bfrg/vim-fzy
# Last Change:  Oct 21, 2022
# License:      Same as Vim itself (see :h license)
# ==============================================================================

if exists('g:loaded_fzy')
    finish
endif
g:loaded_fzy = 1

import autoload '../autoload/fzy.vim'

command -nargs=? -complete=dir FzyFind      fzy.Find(empty(<q-args>) ? getcwd() : <q-args>, 'edit', '')
command -nargs=? -complete=dir FzyFindSplit fzy.Find(empty(<q-args>) ? getcwd() : <q-args>, 'split', <q-mods>)

command -nargs=+ -complete=file FzyGrep      fzy.Grep('buffer', '', <q-args>)
command -nargs=+ -complete=file FzyGrepSplit fzy.Grep('sbuffer', <q-mods>, <q-args>)

command -bar -bang FzyBuffer      fzy.Buffers('buffer', <bang>0, '')
command -bar -bang FzyBufferSplit fzy.Buffers('sbuffer', <bang>0, <q-mods>)

command -bar -bang FzyMarks      fzy.Marks(<bang>0)
command -bar -bang FzyMarksSplit fzy.Marks(<bang>0, <q-mods>)

command -bar FzyOldfiles      fzy.Oldfiles('edit', '')
command -bar FzyOldfilesSplit fzy.Oldfiles('split', <q-mods>)

command -bar FzyArgs      fzy.Arg('edit', false, '')
command -bar FzyArgsSplit fzy.Arg('split', false, <q-mods>)

command -bar FzyLargs      fzy.Arg('edit', true, '')
command -bar FzyLargsSplit fzy.Arg('split', true, <q-mods>)

command -bar FzyTjump      fzy.Tags('tjump', '')
command -bar FzyTjumpSplit fzy.Tags('stjump', <q-mods>)

command -bar FzyHelp fzy.Help('help', <q-mods>)
