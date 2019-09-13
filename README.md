# vim-fzy

vim-fzy provides a simple API for running [fzy][fzy] asynchronously in a Vim
terminal window and invoking a callback function with the selected item.

**Note:** This plugin does not provide any read-to-use commands.

The terminal window will always appear at the bottom and occupy the full width
of the Vim window.


## API usage

The following are simple examples on how to use the API. For more details see
`:help fzy-api`.

#### Switch colorscheme

Fuzzy-select a colorscheme using `fzy`:
```vim
let items = getcompletion('', 'color')

function! s:fzy_cb(item)
    execute 'colorscheme' a:item
endfunction

call fzy#start(items, function('s:fzy_cb'), {
        \ 'height': 10,
        \ 'prompt': '>>> ',
        \ 'statusline': ':colorscheme {name}'
        \ })
```
You will probably want to define a user-command or add a key mapping.

#### Jump to a tag

List all tags and jump to the selected tag:
```vim
let items = uniq(sort(map(taglist('.*'), 'v:val.name')))

function! s:tags_cb(item) abort
    execute 'tjump' escape(a:item, '"')
endfunction

call fzy#start(items, function('s:tags_cb'), {
        \ 'statusline': printf(':tjump [%d tags]', len(items)),
        \ 'height': 15
        \ })
```

#### Find files recursively under current working directory

List file under current working directory using [find(1)][find] and edit the
selected file in the current window:
```vim
" Ignore .git directories"
let items = 'find -name .git -prune -o -print'

call fzy#start(items, {item -> execute('edit ' . item)}, {
        \ 'height': 15,
        \ 'statusline': ':edit {fname}'
        \ })
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
[plug]: https://github.com/junegunn/vim-plug
