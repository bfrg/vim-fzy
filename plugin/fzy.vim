" ==============================================================================
" Fuzzy-select files, buffers, args, tags, help tags, oldfiles, marks
" File:         plugin/fzy.vim
" Author:       bfrg <https://github.com/bfrg>
" Website:      https://github.com/bfrg/vim-fzy
" Last Change:  Jul 19, 2021
" License:      Same as Vim itself (see :h license)
" ==============================================================================

if exists('g:loaded_fzy') || !has('patch-8.1.1828')
    finish
endif
let g:loaded_fzy = 1

command -nargs=? -complete=dir FzyFind      call fzy#find(empty(<q-args>) ? getcwd() : <q-args>, 'edit', '')
command -nargs=? -complete=dir FzyFindSplit call fzy#find(empty(<q-args>) ? getcwd() : <q-args>, 'split', <q-mods>)

command -nargs=+ -complete=file FzyGrep      call fzy#grep('buffer', '', <q-args>)
command -nargs=+ -complete=file FzyGrepSplit call fzy#grep('sbuffer', <q-mods>, <q-args>)

command -bar -bang FzyBuffer      call fzy#buffers('buffer', <bang>0, '')
command -bar -bang FzyBufferSplit call fzy#buffers('sbuffer', <bang>0, <q-mods>)

command -bar -bang FzyMarks     call fzy#marks(<bang>0)
command -bar -bang FzyMarksSplit call fzy#marks(<bang>0, <q-mods>)

command -bar FzyOldfiles      call fzy#oldfiles('edit', '')
command -bar FzyOldfilesSplit call fzy#oldfiles('split', <q-mods>)

command -bar FzyArgs      call fzy#arg('edit', 0, '')
command -bar FzyArgsSplit call fzy#arg('split', 0, <q-mods>)

command -bar FzyLargs      call fzy#arg('edit', 1, '')
command -bar FzyLargsSplit call fzy#arg('split', 1, <q-mods>)

command -bar FzyTjump      call fzy#tags('tjump', '')
command -bar FzyTjumpSplit call fzy#tags('stjump', <q-mods>)

command -bar FzyHelp call fzy#help('help', <q-mods>)
