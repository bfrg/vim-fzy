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

The plugin provides two functions:

* `fzy#start({items}, {callback} [, {options}])`

  Pass a list of items or an external command to [fzy][fzy] and open it in a
  `terminal-window`. `{callback}` is a function that is invoked with the
  selected item.

* `fzy#stop()`

  Stop the process running in the fzy `terminal-window` and close the window.

For more details, see `:help fzy-api` and `:help fzy-examples`.


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
