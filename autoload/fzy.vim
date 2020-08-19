" ==============================================================================
" Run fzy asynchronously inside a Vim terminal-window
" File:         autoload/fzy.vim
" Author:       bfrg <https://github.com/bfrg>
" Website:      https://github.com/bfrg/vim-fzy
" Last Change:  Aug 19, 2020
" License:      Same as Vim itself (see :h license)
" ==============================================================================

let s:save_cpo = &cpoptions
set cpoptions&vim

function s:error(msg) abort
    echohl ErrorMsg | echomsg a:msg | echohl None
endfunction

" Save and restore the view of the current window
" mode:
"   0 - save current view
"   1 - restore old view
"   2 - restore old view and cleanup
function s:window_state(mode) abort
    if a:mode == 0
        let w:fzy_winview = winsaveview()
    elseif a:mode == 1 && exists('w:fzy_winview')
        call winrestview(w:fzy_winview)
    elseif a:mode == 2 && exists('w:fzy_winview')
        call winrestview(w:fzy_winview)
        unlet w:fzy_winview
    endif
endfunction

function s:windo(mode) abort
    for winnr in range(1, winnr('$'))
        call win_execute(win_getid(winnr), printf('call s:window_state(%d)', a:mode))
    endfor
endfunction

function s:exit_cb(ctx, job, status) abort
    " We need to redraw the screen in case a prompt like :tselect shows up after
    " selecting an item. If not redrawn, the popup window remains visible
    if a:ctx.use_popup
        close
        redraw
    else
        let winnr = winnr()
        call win_gotoid(a:ctx.winid)
        execute winnr .. 'close'
        call s:windo(2)
        " Must be called after s:windo(2) or screen flickers when fzy is closed
        " with CTRL-C
        redraw
    endif

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

function s:term_open(opts, ctx) abort
    let cmd = [&shell, &shellcmdflag, a:opts.shellcmd]

    let term_opts = {
            \ 'norestore': 1,
            \ 'exit_cb': funcref('s:exit_cb', [a:ctx]),
            \ 'term_name': 'fzy',
            \ 'term_rows': a:opts.rows
            \ }

    if a:ctx.use_popup
        let bufnr = term_start(cmd, extend(term_opts, {
                \ 'hidden': 1,
                \ 'term_finish': 'close'
                \ }))

        call extend(a:opts.popup, {
                \ 'minwidth': &columns > 80 ? 80 : &columns-4,
                \ 'padding': [0,1,0,1],
                \ 'border': [],
                \ 'borderchars': ['─', '│', '─', '│', '┌', '┐', '┘', '└']
                \ }, 'keep')

        " Stop terminal job when popup window is closed with mouse
        call popup_create(bufnr, extend(a:opts.popup, {
                \ 'minheight': a:opts.rows,
                \ 'callback': {_,val -> val == -2 ? term_getjob(bufnr)->job_stop() : 0}
                \ }))
    else
        call s:windo(0)
        botright let bufnr = term_start(cmd, term_opts)
        setlocal nonumber norelativenumber winfixheight
        let &l:statusline = a:opts.statusline
        call s:windo(1)
    endif

    call setbufvar(bufnr, '&filetype', 'fzy')
    return bufnr
endfunction

" See issue: https://github.com/vim/vim/issues/3522
function fzy#start(items, on_select_cb, ...) abort
    if empty(a:items)
        return s:error('fzy-E10: No items passed')
    endif

    let ctx = {
            \ 'winid': win_getid(),
            \ 'selectfile': tempname(),
            \ 'on_select_cb': a:on_select_cb,
            \ 'use_popup': has_key(a:0 ? a:1 : {}, 'popup') && has('patch-8.2.0204') ? 1 : 0
            \ }

    let opts = extend(a:0 ? copy(a:1) : {}, {
            \ 'exe': exepath('fzy'),
            \ 'lines': 10,
            \ 'statusline': 'fzy-term'
            \ }, 'keep')

    let lines = opts.lines < 3 ? 3 : opts.lines
    let opts.rows = get(opts, 'showinfo') ? lines + 2 : lines + 1

    let fzyopts = printf('--lines=%d', lines)
            \ .. (has_key(opts, 'prompt') ? printf(' --prompt=%s', shellescape(opts.prompt)) : '')
            \ .. (get(opts, 'showinfo') ? ' --show-info' : '')

    let fzycmd = printf('%s %s > %s', opts.exe, fzyopts, ctx.selectfile)

    if type(a:items) ==  v:t_list
        let ctx.itemsfile = tempname()
        let opts.shellcmd = fzycmd .. ' < ' .. ctx.itemsfile
        if executable('mkfifo')
            call system('mkfifo ' .. ctx.itemsfile)
            let fzybuf = s:term_open(opts, ctx)
            call writefile(a:items, ctx.itemsfile)
        else
            call writefile(a:items, ctx.itemsfile)
            let fzybuf = s:term_open(opts, ctx)
        endif
    elseif type(a:items) == v:t_string
        let opts.shellcmd = a:items .. ' | ' .. fzycmd
        let fzybuf = s:term_open(opts, ctx)
    else
        return s:error('fzy-E11: Only list and string supported')
    endif

    return fzybuf
endfunction

function fzy#stop() abort
    if &buftype !=# 'terminal' || bufname('%') !=# 'fzy'
        return s:error('fzy-E12: Not a fzy terminal window')
    endif
    return job_stop(term_getjob(bufnr('%')))
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
