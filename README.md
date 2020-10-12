# vim-fzy

vim-fzy provides a simple API for running the fuzzy-searcher [fzy][fzy]
asynchronously in a Vim terminal window and invoking a callback function with
the selected item.

The terminal buffer can be displayed in either a normal window at the bottom
of the screen, or in a popup window (requires Vim `8.2.0204`).

**Note:** This plugin does not provide any ready-to-use commands. See the
[table](#plugins-using-vim-fzy) below for a list of plugins utilizing the API as
well as the [examples](#examples) section.

<dl>
  <p align="center">
  <a href="https://asciinema.org/a/268637">
    <img src="https://asciinema.org/a/268637.png" width="480">
  </a>
  </p>
</dl>


## Plugins using vim-fzy

| Plugin                       | Items                                             |
|------------------------------|---------------------------------------------------|
| [vim-fzy-builtins][builtins] | buffers, args, tags, `oldfiles`, help tags, marks |
| [vim-fzy-find][fzy-find]     | Files under a specified directory                 |


## API Documentation

This documentation can also be found under <kbd>:help fzy-api</kbd>.

```vim
fzy#start({items}, {callback} [, {options}])
```
Open a new terminal window with `{items}` passed as stdin to fzy. `{callback}`
is a function that is invoked after selecting an item.

`{items}` can be a string or a list of strings. When a string is passed, the
string is run as a command in `'shell'` and its output passed to fzy. If
`{items}` is a list, on systems that support FIFOs, the items are passed through
a FIFO to fzy. On all other systems the items are written to a temporary file on
disk and then passed as stdin to fzy.

`{options}` is an optional dictionary that can contain the following entries:

| Key              | Description                                           | Default                |
| ---------------- | ----------------------------------------------------- | ---------------------- |
| `exe`            | Path to fzy executable.                               | value found in `$PATH` |
| `lines`          | How many lines of results to show.                    | `10`                   |
| `prompt`         | fzy input prompt.                                     | `'> '`                 |
| `showinfo`       | Whether to invoke fzy with `--show-info` option.      | `0`                    |
| `statusline`     | Content for the `statusline` of the terminal window.  | `'fzy-term'`           |
| `term_highlight` | Highlight group for the terminal window.              | `'Terminal'`           |
| `popupwin`       | Display fzy in a popup terminal.                      | `v:false`              |
| `popup`          | Popup window options. Entry must be a dictionary.     | see below              |

The `popup` entry must be a dictionary that can contain the following keys:

| Key               | Description                                                                  | Default                                    |
| ----------------- | ---------------------------------------------------------------------------- | ------------------------------------------ |
| `highlight`       | Highlight group for popup window padding and border.                         | `'Pmenu'`                                  |
| `padding`         | List with numbers defining padding between popup window and its border.      | `[0, 1, 0, 1]`                             |
| `border`          | List with numbers (0 or 1) specifying whether to draw a popup window border. | `[1, 1, 1, 1]`                             |
| `borderchars`     | List with characters used for drawing the border.                            | `['═', '║', '═', '║', '╔', '╗', '╝', '╚']` |
| `borderhighlight` | List with highlight group names for drawing the border.¹                     | `['Pmenu']`                                |
| `minwidth`        | Minimum width of popup window.                                               | `80`                                       |
| `title`           | Title of popup window.                                                       | `''`                                       |

¹When only one item is specified it is used on all four sides.

The popup options are similar to what is passed to `popup_create()`. Other
useful options are `pos`, `line`, `col`, `drag`, `close`, `resize` and `zindex`.
See <kbd>:help popup\_create-arguments</kbd> for more details.

By default the popup window is positioned in the center of the screen. This can
be changed through the `pos`, `line` and `col` entries.

The height of the popup window is set automatically using the `lines`, `padding`
and `border` entries.

When `popupwin` is set to `v:false`, the terminal window will appear at the
bottom of the screen and occupy the full width of the Vim window.


## Examples

Fuzzy-select a colorscheme:
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

Find files under a specified directory using [find(1)][find] and edit the
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
See <kbd>:help fzy-examples</kbd> for more examples.


## Installation

#### Manual Installation

Run the following commands in your terminal:
```bash
$ cd ~/.vim/pack/git-plugins/start
$ git clone https://github.com/bfrg/vim-fzy
$ vim -u NONE -c "helptags vim-fzy/doc" -c q
```
**Note:** The directory name `git-plugins` is arbitrary, you can pick any other
name. For more details see <kbd>:help packages</kbd>.

#### Plugin Managers

Assuming [vim-plug][plug] is your favorite plugin manager, add the following to
your `vimrc`:
```vim
Plug 'bfrg/vim-fzy'
```


## License

Distributed under the same terms as Vim itself. See <kbd>:help license</kbd>.

[fzy]: https://github.com/jhawthorn/fzy
[find]: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/find.html
[builtins]: https://github.com/bfrg/vim-fzy-builtins
[fzy-find]: https://github.com/bfrg/vim-fzy-find
[plug]: https://github.com/junegunn/vim-plug
