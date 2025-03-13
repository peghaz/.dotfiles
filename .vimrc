syntax on
filetype plugin indent on

set ts=2 sts=2 sw=2 et ai " tab space, soft tab space, shift width, auto indent
set number                     " Show current line number
set relativenumber             " Show relative line numbers
set textwidth=280
set mouse=a

" Map Ctrl+S to save the current file
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>a

" Map Ctrl+Q to quit Vim
nnoremap <C-q> :q<CR>
inoremap <C-q> <Esc>:q<CR>

" Setting the leader key <leader> to spacebar
let mapleader = " "

call plug#begin()
  Plug 'ryanoasis/vim-devicons' " Icons pack
  Plug 'scrooloose/nerdcommenter' " Commenting package for vim
  Plug 'mg979/vim-visual-multi' " Allows to select multiple lines with ctrl+n
  Plug 'tpope/vim-surround' " Allows to surround selected text in visual mode with a tag using shift+s
  Plug 'romainl/vim-cool' " Allows better highlighted search
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'junegunn/vim-easy-align'
call plug#end()

let g:NERDCreateDefaultMappings = 1

xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" use <tab> to trigger completion and navigate to the next complete item
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" CoC shortcuts
inoremap <silent><expr> <tab> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<TAB>"
inoremap <silent><expr> <cr> "\<c-g>u\<CR>"
inoremap <silent><expr> <c-@> coc#refresh()
nnoremap <silent> <C-p> :Files<CR>

