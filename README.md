### esa.vim

This is a vimscript for esa (https://esa.io/).

For the latest version please see https://github.com/upamune/esa.vim.

## Usage:

### Implemented :rocket:

- Post current buffer to esa

        :Esa path/to/category/name

- Post selected text to esa

        :'<,'>Esa path/to/category/name

- Create a public (sharing post) esa.

        :Esa -p path/to/category/name

- Open the esa on browser after you post

        :Esa -b

- Copy the URL after you post

        :Esa -c

### Install with [vim-plug](https://github.com/junegunn/vim-plug)

Add the following lines to your `.vimrc`.

    Plug 'mattn/webapi-vim' | Plug 'upamune/esa.vim'

Now restart Vim and run `:PlugInstall`.

### Install with [NeoBundle](https://github.com/Shougo/neobundle.vim)

Add the following line to your `.vimrc`.

    NeoBundle 'upamune/esa.vim', {'depends': 'mattn/webapi-vim'}

## Requirements:

- curl command (http://curl.haxx.se/)
- webapi-vim (https://github.com/mattn/webapi-vim)

## Setup:

You should set a team name.

    let g:esa_team = 'docs'

The plugin stores its credentials in `~/.esa-vim`.

The token is stored in `~/.esa-vim`. If you stop using the plugin, you can
easily remove this file.

