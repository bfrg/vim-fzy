# vim-fzy

vim-fzy provides a simple API for running the fuzzy-searcher [fzy][fzy]
asynchronously in a Vim terminal window and invoking a callback function with
the selected item.

**Note:** This plugin does not provide any ready-to-use commands. See
[available sources](#Available-sources) below for some common extensions.

Currently the terminal window appears at the bottom and occupies the full width
of the Vim window.


## Available sources

| Extension                | Items                                        |
|--------------------------|----------------------------------------------|
| [vim-fzy-common][common] | buffers, args, tags, `oldfiles`, help tags   |


## API usage

The following snippets are simple examples on how to use the API. For more
details see `:help fzy-api`.

#### Switch colorscheme

Fuzzy-select a colorscheme:
```vim
function! s:fzy_cb(item)
    execute 'colorscheme' a:item
endfunction

function! s:setcolors() abort
    let items = getcompletion('', 'color')
    return fzy#start(items, function('s:fzy_cb'), {
            \ 'height': 10,
            \ 'prompt': '▶ ',
            \ 'statusline': ':colorscheme {name}'
            \ })
endfunction

command! -bar Color call s:setcolors()
nnoremap <leader>c :<c-u>call <sid>setcolors()<cr>
```

#### Jump to a tag

List all tags and jump to the selected tag in the current window:
```vim
function! s:tags_cb(item) abort
    execute 'tjump' escape(a:item, '"')
endfunction

function! s:fuzzytags() abort
    let items = uniq(sort(map(taglist('.*'), 'v:val.name')))
    return fzy#start(items, function('s:tags_cb'), {
            \ 'height': 15,
            \ 'statusline': printf(':tjump [%d tags]', len(items))
            \ })
endfunction
command! -bar Tjump call s:fuzzytags()
```

#### Find files recursively under a directory

List files under a specified directory using [find(1)][find] and edit the
selected file in the current window:
```vim
function! s:fuzzyfind(dir) abort
    " Ignore .git directories
    let items = printf('find %s -name .git -prune -o -print', a:dir)
    return fzy#start(items, {item -> execute('edit ' . fnameescape(item))}, {
            \ 'height': 15,
            \ 'prompt': '>> ',
            \ 'statusline': printf(':edit {fname} [directory: %s]', a:dir)
            \ })
endfunction
command! -bar -nargs=? -complete=dir FzyFind call s:fuzzyfind(empty(<q-args>) ? getcwd() : <q-args>)
```


## Installation

#### Manual Installation

Run the following commands in your terminal:
```bash
$ cd ~/.vim/pack/git-plugins/start
$ git clone https://github.com/bfrg/vim-fzy
$ vim -u NONE -c "helptags vim-fzy/doc" -c q
```
**Note:** The directory name `git-plugins` is arbitrary, you can pick any other
name. For more details see `:help packages`.

#### Plugin Managers

Assuming [vim-plug][plug] is your favorite plugin manager, add the following to
your `.vimrc`:
```vim
Plug 'bfrg/vim-fzy'
```


## License

Distributed under the same terms as Vim itself. See `:help license`.

[fzy]: https://github.com/jhawthorn/fzy
[find]: https://pubs.opengroup.org/onlinepubs/009695399/utilities/find.html
[common]: https://github.com/bfrg/vim-fzy-common
[plug]: https://github.com/junegunn/vim-plug
