" BEHAVIOUR
scriptencoding utf-8
set encoding=utf-8

" Allows to press ';' instead of ':' for commands
nore ; :
" Allows to press 'ñ' for commands in spanish keyboards
nore ñ :

set cursorline
set number                      " Line numbers.
set statusline+=%F\ %=%l\:%c
set vb                          " No sounds.
set t_vb=                       " No visual bell

" VISUAL
syntax on                       " Color syntax
colorscheme peachpuff
set list                        " Show invisible characters
set listchars=tab:>·,trail:·    " But only show tabs and trailing whitespace

set shortmess=atI               " Shorten messages and don't show intro
set showmatch                   " Show matching brackets
set showcmd                     " Show the command I'm writing

set laststatus=2                " Status bar.

