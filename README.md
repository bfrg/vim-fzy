# vim-fzy

vim-fzy provides a simple API for running the fuzzy-searcher [fzy][fzy]
asynchronously in a Vim terminal window and invoking a callback function with
the selected item.

**Note:** This plugin does not provide any ready-to-use commands. See the table
below for a list of plugins utilizing the API.

<dl>
  <p align="center">
  <a href="https://asciinema.org/a/268637">
    <img src="https://asciinema.org/a/268637.png" width="480">
  </a>
  </p>
</dl>


## Available extensions for vim-fzy

| Plugin                       | Items                                             |
|------------------------------|---------------------------------------------------|
| [vim-fzy-builtins][builtins] | buffers, args, tags, `oldfiles`, help tags, marks |
| [vim-fzy-find][fzy-find]     | Files under a specified directory                 |


## Usage

### API

vim-fzy provides two functions:

1. **`fzy#start({items}, {callback} [, {options}])`**<br/>
Open a new terminal window with `{items}` passed as stdin to fzy.
`{callback}` is a function that is invoked with the selected item.

2. **`fzy#stop()`**<br/>
Stop the process running in the focused terminal window and close the window.

See `:help fzy-api` for more details.

### Examples

1. Fuzzy-select a colorscheme:
```vim
function! s:fzy_cb(item)
    execute 'colorscheme' a:item
endfunction

function! s:setcolors() abort
    let items = getcompletion('', 'color')
    return fzy#start(items, function('s:fzy_cb'), {
            \ 'lines': 10,
            \ 'prompt': '▶ ',
            \ 'statusline': ':colorscheme {name}'
            \ })
endfunction

command! -bar Color call s:setcolors()
```

2. Find files under a specified directory using [find(1)][find] and edit the
   selected file in the current window:
```vim
function! s:fuzzyfind(dir) abort
    " Ignore .git directories
    let items = printf('find %s -name .git -prune -o -type f -print', a:dir)
    return fzy#start(items, {i -> execute('edit ' . fnameescape(i))}, {
            \ 'statusline': printf(':edit {fname} [directory: %s]', a:dir)
            \ })
endfunction

command! -bar -nargs=? -complete=dir Find
        \ call s:fuzzyfind(empty(<q-args>) ? getcwd() : <q-args>)
```
See also `:help fzy-examples`.


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
[find]: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/find.html
[builtins]: https://github.com/bfrg/vim-fzy-builtins
[fzy-find]: https://github.com/bfrg/vim-fzy-find
[plug]: https://github.com/junegunn/vim-plug
