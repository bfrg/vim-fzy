vim9script
# ==============================================================================
# Run fzy asynchronously inside a Vim terminal-window
# File:         autoload/fzy.vim
# Author:       bfrg <https://github.com/bfrg>
# Website:      https://github.com/bfrg/vim-fzy
# Last Change:  Oct 21, 2022
# License:      Same as Vim itself (see :h license)
# ==============================================================================

const findcmd: list<string> =<< trim END
    find
      -name '.*'
      -a '!' -name .
      -a '!' -name .gitignore
      -a '!' -name .vim
      -a -prune
      -o '(' -type f -o -type l ')'
      -a -print 2> /dev/null
    | cut -b3-
END

def Error(msg: string)
    echohl ErrorMsg | echomsg msg | echohl None
enddef

def Update_cmd_history(cmd: string)
    if get(get(g:, 'fzy', {}), 'histadd', false)
        histadd('cmd', cmd)
    endif
enddef

def Tryexe(cmd: string)
    try
        execute cmd
    catch
        echohl ErrorMsg
        echomsg matchstr(v:exception, '^Vim\%((\a\+)\)\=:\zs.*')
        echohl None
    endtry
enddef

def Exit_cb(ctx: dict<any>, job: job, status: number)
    # Redraw screen in case a prompt like :tselect shows up after selecting an
    # item. If not redrawn, popup window remains visible
    if ctx.popupwin
        close
        redraw
    else
        const winnr: number = winnr()
        win_gotoid(ctx.winid)
        execute $':{winnr}close'
        redraw
    endif

    if filereadable(ctx.selectfile)
        try
            ctx.on_select_cb(readfile(ctx.selectfile)[0])
        catch /^Vim\%((\a\+)\)\=:E684/
        endtry
    endif

    delete(ctx.selectfile)
    if has_key(ctx, 'itemsfile')
        delete(ctx.itemsfile)
    endif
enddef

def Term_open(opts: dict<any>, ctx: dict<any>): number
    const cmd: list<string> = [&shell, &shellcmdflag, opts.shellcmd]

    var term_opts: dict<any> = {
        norestore: true,
        exit_cb: funcref(Exit_cb, [ctx]),
        term_name: 'fzy',
        term_rows: opts.rows
    }

    if has_key(opts, 'term_highlight')
        extend(term_opts, {term_highlight: opts.term_highlight})
    endif

    var bufnr: number
    if ctx.popupwin
        if !has_key(opts, 'term_highlight')
            extend(term_opts, {term_highlight: 'Pmenu'})
        endif

        bufnr = term_start(cmd, extend(term_opts, {
            hidden: true,
            term_finish: 'close'
        }))

        extend(opts.popup, {
            minwidth: &columns > 80 ? 80 : &columns - 4,
            padding: [0, 1, 0, 1],
            border: []
        }, 'keep')

        # Stop terminal job when popup window is closed with mouse
        popup_create(bufnr, deepcopy(opts.popup)->extend({
            minheight: opts.rows,
            callback: (_, i) => i == -2 ? bufnr->term_getjob()->job_stop() : 0
        }))
    else
        botright bufnr = term_start(cmd, term_opts)
        &l:number = false
        &l:relativenumber = false
        &l:winfixheight = true
        &l:bufhidden = 'wipe'
        &l:statusline = opts.statusline
    endif

    setbufvar(bufnr, '&filetype', 'fzy')
    return bufnr
enddef

def Opts(title: string, space: bool = false): dict<any>
    var opts: dict<any> = get(g:, 'fzy', {})->deepcopy()->extend({statusline: title})
    get(opts, 'popup', {})->extend({title: space ? ' ' .. title : title})
    return opts
enddef

def Find_cb(dir: string, vim_cmd: string, choice: string)
    var fpath: string = fnamemodify(dir, ':p:s?/$??') .. '/' .. choice
    fpath = fpath->resolve()->fnamemodify(':.')->fnameescape()
    Update_cmd_history($'{vim_cmd} {fpath}')
    Tryexe($'{vim_cmd} {fpath}')
enddef

def Open_file_cb(vim_cmd: string, choice: string)
    const fname: string = fnameescape(choice)
    Update_cmd_history($'{vim_cmd} {fname}')
    Tryexe($'{vim_cmd} {fname}')
enddef

def Open_tag_cb(vim_cmd: string, choice: string)
    Update_cmd_history(vim_cmd .. ' ' .. choice)
    Tryexe(vim_cmd .. ' ' .. escape(choice, '"'))
enddef

def Marks_cb(split_cmd: string, bang: bool, item: string)
    if !empty(split_cmd)
        execute split_cmd
    endif
    const cmd: string = bang ? "g`" : "`"
    Tryexe($'normal! {cmd}{item[1]}')
enddef

def Grep_cb(efm: string, vim_cmd: string, choice: string)
    const items: list<any> = getqflist({lines: [choice], efm: efm})->get('items', [])
    if empty(items) || !items[0].bufnr
        Error('fzy: no valid item selected')
        return
    endif
    setbufvar(items[0].bufnr, '&buflisted', 1)
    const cmd: string = $'{vim_cmd} {items[0].bufnr} | call cursor({items[0].lnum}, {items[0].col})'
    Update_cmd_history(cmd)
    Tryexe(cmd)
enddef

export def Start(items: any, On_select_cb: func, options: dict<any> = {}): number
    if empty(items)
        Error('fzy-E10: No items passed')
        return 0
    endif

    var ctx: dict<any> = {
        winid: win_getid(),
        selectfile: tempname(),
        on_select_cb: On_select_cb,
        popupwin: get(options, 'popupwin') ? true : false
    }

    var opts: dict<any> = options->deepcopy()->extend({
        exe: exepath('fzy'),
        prompt: '> ',
        lines: 10,
        showinfo: 0,
        popup: {},
        histadd: false,
        statusline: 'fzy-term'
    }, 'keep')

    if !executable(opts.exe)
        Error($'fzy: executable "{opts.exe}" not found')
        return 0
    endif

    var lines: number = opts.lines < 3 ? 3 : opts.lines
    opts.rows = opts.showinfo ? lines + 2 : lines + 1

    const fzycmd: string = printf('%s --lines=%d --prompt=%s %s > %s',
        opts.exe,
        lines,
        shellescape(opts.prompt),
        opts.showinfo ? '--show-info' : '',
        ctx.selectfile
    )

    var fzybuf: number
    if type(items) ==  v:t_list
        ctx.itemsfile = tempname()

        # Automatically resize terminal window
        if len(items) < lines
            lines = len(items) < 3 ? 3 : len(items)
            opts.rows = get(opts, 'showinfo') ? lines + 2 : lines + 1
        endif

        opts.shellcmd = $'{fzycmd} < {ctx.itemsfile}'
        if executable('mkfifo')
            system($'mkfifo {ctx.itemsfile}')
            fzybuf = Term_open(opts, ctx)
            writefile(items, ctx.itemsfile)
        else
            writefile(items, ctx.itemsfile)
            fzybuf = Term_open(opts, ctx)
        endif
    elseif type(items) == v:t_string
        opts.shellcmd = $'{items} | {fzycmd}'
        fzybuf = Term_open(opts, ctx)
    else
        Error('fzy-E11: Only list and string supported')
        return 0
    endif

    return fzybuf
enddef

export def Stop()
    if &buftype != 'terminal' || bufname() != 'fzy'
        Error('fzy-E12: Not a fzy terminal window')
        return
    endif
    bufnr()->term_getjob()->job_stop()
enddef

export def Find(dir: string, vim_cmd: string, mods: string)
    if !isdirectory(expand(dir, true))
        Error($'fzy-find: Directory "{expand(dir, true)}" does not exist')
        return
    endif

    const path: string = dir->expand(true)->fnamemodify(':~')->simplify()
    const cmd: string = printf('cd %s; %s',
        expand(path, true)->shellescape(),
        get(g:, 'fzy', {})->get('findcmd', join(findcmd))
    )
    const editcmd: string = empty(mods) ? vim_cmd : (mods .. ' ' .. vim_cmd)
    const stl: string = $':{editcmd} [directory: {path}]'
    Start(cmd, funcref(Find_cb, [path, editcmd]), Opts(stl))
enddef

export def Buffers(edit_cmd: string, bang: bool, mods: string)
    const cmd: string = empty(mods) ? edit_cmd : (mods .. ' ' .. edit_cmd)
    const items: list<any> = range(1, bufnr('$'))
        ->filter(bang ? (_, i: number): bool => bufexists(i) : (_, i: number): bool => buflisted(i))
        ->mapnew((_, i: number): any => i->bufname()->empty() ? i : i->bufname()->fnamemodify(':~:.'))
    const stl: string = printf(':%s (%s buffers)', cmd, bang ? 'all' : 'listed')
    Start(items, funcref(Open_file_cb, [cmd]), Opts(stl))
enddef

export def Oldfiles(edit_cmd: string, mods: string)
    const cmd: string = empty(mods) ? edit_cmd : (mods .. ' ' .. edit_cmd)
    const items: list<string> = v:oldfiles
        ->copy()
        ->filter((_, i: string): bool => i->fnamemodify(':p')->filereadable())
        ->map((_, i: string): string => fnamemodify(i, ':~:.'))
    const stl: string = $':{cmd} (oldfiles)'
    Start(items, funcref(Open_file_cb, [cmd]), Opts(stl))
enddef

export def Arg(edit_cmd: string, local: bool, mods: string)
    const items: list<string> = local ? argv() : argv(-1, -1)
    const str: string = local ? 'local arglist' : 'global arglist'
    const cmd: string = empty(mods) ? edit_cmd : (mods .. ' ' .. edit_cmd)
    Start(items, funcref(Open_file_cb, [cmd]), Opts($':{cmd} ({str})'))
enddef

export def Help(help_cmd: string, mods: string)
    const cmd: string = empty(mods) ? help_cmd : (mods .. ' ' .. help_cmd)
    const items: string = 'cut -f 1 ' .. findfile('doc/tags', &runtimepath, -1)->join()
    const stl: string = $':{cmd} (helptags)'
    Start(items, funcref(Open_tag_cb, [cmd]), Opts(stl))
enddef

export def Grep(edit_cmd: string, mods: string, args: string)
    const cmd: string = empty(mods) ? edit_cmd : (mods .. ' ' .. edit_cmd)
    const grep_cmd: string = get(g:, 'fzy', {})->get('grepcmd', &grepprg) .. ' ' .. args
    const grep_efm: string = get(g:, 'fzy', {})->get('grepformat', &grepformat)
    const stl: string = $':{cmd} ({grep_cmd})'
    Start(grep_cmd, funcref(Grep_cb, [grep_efm, cmd]), Opts(stl))
enddef

export def Tags(tags_cmd: string, mods: string)
    const cmd: string = empty(mods) ? tags_cmd : (mods .. ' ' .. tags_cmd)
    const items: any = executable('sed') && executable('cut') && executable('sort') && executable('uniq')
        ? printf("sed '/^!_TAG_/ d' %s | cut -f 1 | sort | uniq", tagfiles()->join())
        : taglist('.*')->mapnew((_, i: dict<any>): string => i.name)->sort()->uniq()
    const stl: string = printf(':%s [%s]', cmd, tagfiles()->map((_, i: string): string => fnamemodify(i, ':~:.'))->join(', '))
    Start(items, funcref(Open_tag_cb, [cmd]), Opts(stl))
enddef

export def Marks(bang: bool, ...args: list<string>)
    const cmd: string = !empty(args) ? args[0] .. ' split' : ''
    const output: list<string> = execute('marks')->split('\n')
    Start(output[1 :], funcref(Marks_cb, [cmd, bang]), Opts(output[0], true))
enddef
