set hlsearch
set number relativenumber
autocmd BufReadPost * silent! normal! g`"zv

set tabstop=2
set shiftwidth=2
set noexpandtab

set splitright

let mapleader = " "
let maplocalleader = " "

let updatetime = 300
let signcolumn = "yes"

set clipboard+=unnamedplus

" enable with :set list, disable with :set nolist	set listchars=eol:¬,tab:>·,trail:~,extends:>,precedes:<,space:␣
set listchars=eol:¬,tab:>·,trail:~,extends:>,precedes:<,space:␣ 
