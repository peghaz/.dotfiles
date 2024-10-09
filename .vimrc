syntax on
filetype plugin indent on

set ts=2 sts=2 sw=2 et ai " tab space, soft tab space, shift width, auto indent
set rnu " relative line number
set textwidth=280

call plug#begin()
  Plug 'whatyouhide/vim-gotham'
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
  Plug 'ryanoasis/vim-devicons'
  Plug 'scrooloose/nerdcommenter'
  Plug 'mg979/vim-visual-multi'
  Plug 'tpope/vim-surround'
  Plug 'romainl/vim-cool'
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'davidhalter/jedi-vim'
  Plug 'cdelledonne/vim-cmake'
  Plug 'tranvansang/octave.vim'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'junegunn/vim-easy-align'
  Plug 'jiangmiao/auto-pairs'
  Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
  Plug 'Xuyuanp/nerdtree-git-plugin'
call plug#end()

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

" Setting the GUI themes
set termguicolors
colorscheme gotham
