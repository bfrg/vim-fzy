" ==============================================================================
" Run fzy asynchronously inside a Vim terminal-window
" File:         autoload/fzy.vim
" Author:       bfrg <https://github.com/bfrg>
" Website:      https://github.com/bfrg/vim-fzy
" Last Change:  Sep 12, 2019
" License:      Same as Vim itself (see :h license)
" ==============================================================================

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:defaults = {'height': 11, 'prompt': '>>> ', 'statusline': 'fzy-term'}
let s:fzybuf = 0
let s:filename = tempname()

function! s:error(msg) abort
    echohl ErrorMsg
    echomsg a:msg
    echohl None
    return -1
endfunction

" Save and restore the view of the current window
" mode:
"   0 - save current view
"   1 - restore old view
"   2 - restore old view and cleanup
function! s:window_state(mode) abort
    if a:mode == 0
        let w:winview = winsaveview()
    elseif a:mode == 1 && exists('w:winview')
        call winrestview(w:winview)
    elseif a:mode == 2 && exists('w:winview')
        call winrestview(w:winview)
        unlet w:winview
    endif
endfunction

function! s:windo(mode) abort
    let winid = win_getid()
    try
        keepjumps noautocmd windo call s:window_state(a:mode)
    finally
        call win_gotoid(winid)
    endtry
endfunction

" See issue: https://github.com/vim/vim/issues/3522
function! fzy#start(items, on_select_cb, ...) abort
    if empty(a:items)
        return s:error('vim-fzy: No items passed')
    endif

    let opts = a:0 ? a:1 : s:defaults
    let winid = win_getid()
    let fzy = printf('fzy --lines=%d --prompt=%s > %s',
            \ get(opts, 'height', s:defaults.height) - 1,
            \ shellescape(get(opts, 'prompt', s:defaults.prompt)),
            \ s:filename
            \ )

    if type(a:items) ==  v:t_list
        let shell_cmd = printf('printf %s | %s',
                \ shellescape(substitute(join(a:items, '\n'), '%', '%%', 'g')),
                \ fzy
                \ )
    elseif type(a:items) == v:t_string
        let shell_cmd = a:items .. '|' .. fzy
    else
        return s:error('vim-fzy: Only list and string supported')
    endif

    function! s:exit_cb(job, status) abort closure
        close
        call s:windo(2)
        call win_gotoid(winid)
        if filereadable(s:filename)
            try
                call a:on_select_cb(readfile(s:filename)[0])
            catch /^Vim\%((\a\+)\)\=:E684/
            endtry
        endif
        call delete(s:filename)
    endfunction

    call s:windo(0)
    botright let s:fzybuf = term_start([&shell, &shellcmdflag, shell_cmd], {
            \ 'norestore': 1,
            \ 'exit_cb': function('s:exit_cb'),
            \ 'term_name': 'fzy',
            \ 'term_rows': get(opts, 'height', s:defaults.height)
            \ })
    call term_wait(s:fzybuf, 20)
    setlocal nonumber norelativenumber winfixheight filetype=fzy
    let &l:statusline = get(opts, 'statusline', s:defaults.statusline)
    call s:windo(1)

    return s:fzybuf
endfunction

function! fzy#stop() abort
    return job_stop(term_getjob(s:fzybuf))
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
