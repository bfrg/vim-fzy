" ==============================================================================
" Run fzy asynchronously inside a Vim terminal-window
" File:         autoload/fzy.vim
" Author:       bfrg <https://github.com/bfrg>
" Website:      https://github.com/bfrg/vim-fzy
" Last Change:  Sep 19, 2019
" License:      Same as Vim itself (see :h license)
" ==============================================================================

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:defaults = {'height': 11, 'prompt': '>>> ', 'statusline': 'fzy-term'}

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

function! s:exit_cb(job, status) abort dict
    close
    call s:windo(2)
    call win_gotoid(self.winid)
    if filereadable(self.selectfile)
        try
            call self.on_select_cb(readfile(self.selectfile)[0])
        catch /^Vim\%((\a\+)\)\=:E684/
        endtry
    endif
    call delete(self.selectfile)
    call delete(self.itemsfile)
endfunction

" See issue: https://github.com/vim/vim/issues/3522
function! fzy#start(items, on_select_cb, ...) abort
    if empty(a:items)
        return s:error('fzy-E10: No items passed')
    endif

    let exit_cb_ctx = {
            \ 'winid': win_getid(),
            \ 'selectfile': tempname(),
            \ 'itemsfile': tempname(),
            \ 'on_select_cb': a:on_select_cb
            \ }

    let opts = a:0 ? a:1 : s:defaults
    let fzy = printf('fzy --lines=%d --prompt=%s > %s',
            \ get(opts, 'height', s:defaults.height) - 1,
            \ shellescape(get(opts, 'prompt', s:defaults.prompt)),
            \ exit_cb_ctx.selectfile
            \ )

    if type(a:items) ==  v:t_list
        let printargs = shellescape(substitute(join(a:items, '\n'), '%', '%%', 'g'))
        if len(printargs) > 131071
            call writefile(a:items, exit_cb_ctx.itemsfile)
            let shellcmd = fzy .. ' < ' .. exit_cb_ctx.itemsfile
        else
            let shellcmd = printf('command printf %s | %s', printargs, fzy)
        endif
    elseif type(a:items) == v:t_string
        let shellcmd = a:items .. '|' .. fzy
    else
        return s:error('fzy-E11: Only list and string supported')
    endif

    call s:windo(0)
    botright let fzybuf = term_start([&shell, &shellcmdflag, shellcmd], {
            \ 'norestore': 1,
            \ 'exit_cb': funcref('s:exit_cb', exit_cb_ctx),
            \ 'term_name': 'fzy',
            \ 'term_rows': get(opts, 'height', s:defaults.height)
            \ })
    call term_wait(fzybuf, 20)
    setlocal nonumber norelativenumber winfixheight filetype=fzy
    let &l:statusline = get(opts, 'statusline', s:defaults.statusline)
    call s:windo(1)

    return fzybuf
endfunction

function! fzy#stop() abort
    if &buftype !=# 'terminal' || bufname('%') !=# 'fzy'
        return s:error('fzy-E12: Not a fzy terminal window')
    endif
    return job_stop(term_getjob(bufnr('%')))
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
