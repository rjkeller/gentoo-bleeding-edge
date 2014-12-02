" General settings
set nocompatible "be iMproved
set number       "show line numbers
set tenc=utf8    "terminal encoding is UTF-8
set enc=utf8     "character encoding is UTF-8
set laststatus=2 "always show status line

" vundle (plugin manager)
filetype off "required for vundle
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" Bundles
Bundle 'gmarik/vundle'
Bundle 'vim-scripts/ctrlp.vim'
Bundle 'vim-scripts/Tagbar'
Bundle 'vim-scripts/The-NERD-tree'
Bundle 'vim-scripts/UltiSnips'
Bundle 'vim-scripts/Wombat'

" Syntax
syntax on
filetype plugin indent on
"format the code in current buffer with astyle by pressing leader-ta
nmap <Leader>ta :%!astyle --style=ansi --indent=tab --indent-switches --unpad-paren --keep-one-line-statements --keep-one-line-blocks --align-pointer=type --lineend=linux --suffix=none --quiet<CR>

" Menu / Completion
set wildmenu
set wildmode=list:longest,full
set completeopt=menuone,menu,longest,preview
" automatically open and close the popup menu / preview window
au CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endif

" Search / Highlight
set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch
set showcmd

" Colours
colorscheme wombat

" Runtime settings
runtime ftplugin/man.vim

" file / buffer with NERD-tree
nmap <silent> <Leader>ntt :NERDTreeToggle<CR>
nmap <silent> <Leader>ntf :NERDTreeFind<CR>
" outline for C / C++ code in current buffer with tagbar
nmap <silent> <Leader>tb :TagbarToggle<CR>
" buffer explorer (uses CtrlP)
nmap <Leader>be :CtrlPBuffer<CR>

" Ignore files (also works in CtrlP)
set wildignore+=*.so,*/build/*            "ignore C++ build / output files
set wildignore+=*/.git/*,*/.hg/*,*/.svn/* "ignore SCM directories

" ctags / cscope
" Build tags of your own project with leader-tt
nmap <Leader>tt :call UpdateTags()<CR>

" Functions
func UpdateTags()
	execute "!ctags -R --sort=yes --c++-kinds=+p --fields=+iaS --extra=+q ."
	execute "!cscope -b -R"
endfunc

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
map <C-n> :NERDTreeToggle<CR>

autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
