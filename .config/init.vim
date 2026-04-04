let g:plug_home = '~/.vim/pluggos'

call plug#begin(g:plug_home)
" search
Plug 'brooth/far.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
" UI
Plug 'chriskempson/base16-vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" Latex
Plug 'lervag/vimtex'
Plug 'Konfekt/FastFold'
Plug 'matze/vim-tex-fold'
" File access
Plug 'jeetsukumaran/vim-filebeagle'
" Git
Plug 'lewis6991/gitsigns.nvim'
Plug 'tpope/vim-fugitive'
" LSP
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'saghen/blink.cmp', { 'tag': 'v1.*' }
call plug#end()

" Colorscheme
" colorscheme vim
colorscheme retrobox

" Config gitsigns
lua require('gitsigns').setup()

" Config options
lua require('options')

" Config LSP
lua require('lsp')

" Config misc to autoload changes
set autoread
au FocusGained,BufEnter * checktime

" Config latex
let g:tex_flavor = "latex"
let g:tex_conceal = ''

" Spaces & Tabs {{{
set tabstop=4       " number of visual spaces per TAB
set softtabstop=4   " number of spaces in tab when editing
set shiftwidth=4    " number of spaces to use for autoindent
set expandtab       " tabs are space
set autoindent
set copyindent      " copy indent from the previous line
" }}} Spaces & Tabs

" Set fugitive behaviour
" Need some logic to avoid errors handling splitting + closing
augroup MoveFugitiveWindow
  autocmd!
  autocmd FileType fugitive call timer_start(1, {-> execute('wincmd L')})
augroup END

