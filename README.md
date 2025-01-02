# pkgman.nvim

> [!Note]
> 100%-compatible with Termux

Install packages directly in your Vim/NeoVim

# Installation

Using [lazy.vim](https://github.com/folke/lazy.nvim):
```lua
{
  "TwoSpikes/pkgman.nvim",
}
```

Using [vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'TwoSpikes/pkgman.nvim'
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use 'TwoSpikes/pkgman.nvim'
```

Using [pckr.nvim](https://github.com/lewis6991/pckr.nvim):
```lua
'TwoSpikes/pkgman.nvim'
```

Using [dein](https://github.com/Shougo/dein.vim):
```vim
call dein#add('TwoSpikes/pkgman.nvim')
```

Using [paq-nvim](https://github.com/savq/paq-nvim):
```lua
'TwoSpikes/pkgman.nvim'
```

Using [Pathogen](https://github.com/tpope/vim-pathogen):
```console
$ cd ~/.vim/bundle && git clone https://github.com/TwoSpikes/pkgman.nvim
```

Using Vim built-in package manager (requires Vim v.8.0+) ([help](https://vimhelp.org/repeat.txt.html#packages) or `:h packages`):
```console
$ cd ~/.vim/pack/test/start/ && git clone https://github.com/TwoSpikes/pkgman.nvim
```

# Install a package

```vim
:call pkgman#setup()
:call pkgman#open()
```

Then press `I` (<kbd>Shift</kbd><kbd>i</kbd>) and type `neofetch`. Then press <kbd>Enter</kbd>. Then wait until `neofetch` installs.
