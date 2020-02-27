" ==============================================================================
" Run fzy asynchronously inside a Vim terminal-window
" File:         autoload/fzy.vim
" Author:       bfrg <https://github.com/bfrg>
" Website:      https://github.com/bfrg/vim-fzy
" Last Change:  Feb 27, 2020
" License:      Same as Vim itself (see :h license)
" ==============================================================================

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:defaults = {
        \ 'exe': exepath('fzy'),
        \ 'lines': 10,
        \ 'statusline': 'fzy-term'
        \ }

function! s:error(msg) abort
    echohl ErrorMsg | echomsg a:msg | echohl None
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
    for winnr in range(1, winnr('$'))
        call win_execute(win_getid(winnr), printf('call s:window_state(%d)', a:mode))
    endfor
endfunction

function! s:exit_cb(ctx, job, status) abort
    let winnr = winnr()
    call win_gotoid(a:ctx.winid)
    execute winnr .. 'close'
    call s:windo(2)
    if filereadable(a:ctx.selectfile)
        try
            call a:ctx.on_select_cb(readfile(a:ctx.selectfile)[0])
        catch /^Vim\%((\a\+)\)\=:E684/
        endtry
    endif
    call delete(a:ctx.selectfile)
    if has_key(a:ctx, 'itemsfile')
        call delete(a:ctx.itemsfile)
    endif
endfunction

function! s:term_open(shellcmd, rows, exit_cb_ctx)
    botright let bufnr = term_start([&shell, &shellcmdflag, a:shellcmd], {
            \ 'norestore': 1,
            \ 'exit_cb': funcref('s:exit_cb', [a:exit_cb_ctx]),
            \ 'term_name': 'fzy',
            \ 'term_rows': a:rows
            \ })
    return bufnr
endfunction

" See issue: https://github.com/vim/vim/issues/3522
function! fzy#start(items, on_select_cb, ...) abort
    if empty(a:items)
        return s:error('fzy-E10: No items passed')
    endif

    let ctx = {
            \ 'winid': win_getid(),
            \ 'selectfile': tempname(),
            \ 'on_select_cb': a:on_select_cb
            \ }

    let opts = extend(a:0 ? a:1 : {}, s:defaults, 'keep')
    let rows = get(opts, 'showinfo') ? (opts.lines + 2) : (opts.lines + 1)
    let fzyopts = printf('--lines=%d', opts.lines < 4 ? 3 : opts.lines)
            \ .. (has_key(opts, 'prompt') ? printf(' --prompt=%s', shellescape(opts.prompt)) : '')
            \ .. (get(opts, 'showinfo') ? ' --show-info' : '')

    let fzy = printf('%s %s > %s', opts.exe, fzyopts, ctx.selectfile)

    call s:windo(0)
    if type(a:items) ==  v:t_list
        let ctx.itemsfile = tempname()
        let shellcmd = fzy .. ' < ' .. ctx.itemsfile
        if executable('mkfifo')
            call system('mkfifo ' .. ctx.itemsfile)
            let fzybuf = s:term_open(shellcmd, rows, ctx)
            call writefile(a:items, ctx.itemsfile)
        else
            call writefile(a:items, ctx.itemsfile)
            let fzybuf = s:term_open(shellcmd, rows, ctx)
        endif
    elseif type(a:items) == v:t_string
        let shellcmd = a:items .. ' | ' .. fzy
        let fzybuf = s:term_open(shellcmd, rows, ctx)
    else
        return s:error('fzy-E11: Only list and string supported')
    endif

    call term_wait(fzybuf, 20)
    setlocal nonumber norelativenumber winfixheight filetype=fzy
    let &l:statusline = opts.statusline
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
