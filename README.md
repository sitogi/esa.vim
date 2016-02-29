### esa.vim

This is a vimscript for esa (https://esa.io/).

For the latest version please see https://github.com/upamune/esa-vim.

## Usage:

### Implemented :rocket:

- Post current buffer to esa, using default privacy option.

        :Esa path/to/category/post

- Post selected text to esa, using default privacy option.
  This applies to all permutations listed below (except multi).

        :'<,'>Esa path/to/category/post

- Create a public esa.
  (Only relevant if you've set esas to be private by default.)

        :Esa -p path/to/category/post


### Not Implemented Yet :bow:

- Edit the esa with post_id '123' (you need to have opened the esa buffer
  first).

        :Esa -e 123

- List your team posts with post id.

        :Esa -l

- List posts with post id from user "upamune".

        :Esa -l upamune

- Open the esa on browser after you post or update it.

        :Esa -b

### Install with [vim-plug](https://github.com/junegunn/vim-plug)

Add the following lines to your `.vimrc`.

    Plug 'mattn/webapi-vim' | Plug 'upamune/esa-vim'

Now restart Vim and run `:PlugInstall`.

### Install with [NeoBundle](https://github.com/Shougo/neobundle.vim)

Add the following line to your `.vimrc`.

    NeoBundle 'upamune/esa-vim', {'depends': 'upamune/webapi-vim'}

## Requirements:

- curl command (http://curl.haxx.se/)
- webapi-vim (https://github.com/mattn/webapi-vim)

## Setup:

You should set a team name.

    let g:esa_team = 'docs'

The plugin stores its credentials in `~/.esa-vim`.

The token is stored in `~/.esa-vim`. If you stop using the plugin, you can
easily remove this file.

