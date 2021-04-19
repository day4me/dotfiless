call plug#begin('~/.local/share/nvim/plugged')
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'sonph/onehalf', {'rtp': 'vim'}
Plug 'itchyny/lightline.vim'
call plug#end()

colorscheme onehalfdark
let g:lightline = {
  \ 'colorscheme': 'onehalfdark'
  \ }

set clipboard=unnamedplus
set mouse=a
