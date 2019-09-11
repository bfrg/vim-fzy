# vim-fzy

Run [fzy][fzy] asynchronously in a Vim terminal window.


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
Plug 'bfrg/vim-qf-preview'
```


## License

Distributed under the same terms as Vim itself. See `:help license`.


[fzy]: https://github.com/jhawthorn/fzy
[plug]: https://github.com/junegunn/vim-plug
