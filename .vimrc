" ===================================================================
" GENERAL SETTINGS
" ===================================================================
set nocompatible              " Use Vim settings, not Vi
filetype plugin indent on     " Enable filetype detection and indentation
syntax on                     " Enable syntax highlighting

" ===================================================================
" EDITOR BEHAVIOR
" ===================================================================
set hidden                    " Allow buffer switching without saving
set autoread                  " Auto-reload files changed outside Vim
set nobackup noswapfile       " Don't create backup/swap files
set encoding=utf8             " UTF-8 encoding
set spelllang=en_us          " English spell checking
set backspace=2              " Make backspace work as expected
set ttyfast                  " Faster terminal redrawing

" ===================================================================
" VISUAL SETTINGS
" ===================================================================
set number                    " Show line numbers
set ruler                     " Show cursor position
set laststatus=2              " Always show status line
set scrolloff=4               " Keep 4 lines visible when scrolling
set nowrap                    " Don't wrap long lines
set wildmenu                  " Enhanced command completion
set wildmode=list:longest,full " Command completion behavior

" ===================================================================
" INDENTATION & TABS
" ===================================================================
set autoindent                " Copy indent from current line
set smartindent               " Smart indenting for code
set expandtab                 " Use spaces instead of tabs
set smarttab                  " Smart tab behavior
set tabstop=2                 " Display tabs as 2 spaces
set shiftwidth=2              " Use 2 spaces for indentation
" Note: Later settings override to 4 spaces - reconciled below

" ===================================================================
" SEARCH SETTINGS
" ===================================================================
set ignorecase                " Case-insensitive search
set smartcase                 " Case-sensitive if uppercase used
set incsearch                 " Show matches while typing
set path+=**                  " Search recursively for files
set grepprg=grep\ -irn        " Grep settings

" ===================================================================
" TRUE COLOR SUPPORT
" ===================================================================
if empty($TMUX)
  if has("nvim")
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
  endif
  if has("termguicolors")
    set termguicolors
  endif
endif

" ===================================================================
" PLUGIN MANAGEMENT (vim-plug)
" ===================================================================
if !empty(globpath(&rtp, 'autoload/plug.vim'))
  call plug#begin()

  " Theme
  Plug 'joshdick/onedark.vim'

  " File explorer
  Plug 'preservim/nerdtree'
  Plug 'Xuyuanp/nerdtree-git-plugin'

  " Fuzzy finder
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'

  call plug#end()

  " Load theme after plugins
  colorscheme onedark

  " NERDTree configuration
  let g:NERDTreeMouseMode=2
  autocmd VimEnter * NERDTree | wincmd p
  autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
endif

" ===================================================================
" KEY MAPPINGS
" ===================================================================
" Window navigation
nnoremap <C-Right> <C-w>w
nnoremap <C-Left> <C-w>W
nnoremap <C-Up> :buffers<cr>:buffer<space>

" FZF file search (only if plugin loaded)
if !empty(globpath(&rtp, 'plugged/fzf.vim'))
  nnoremap <C-p> :Files<CR>
endif

" Code commenting
noremap <silent> cc :<C-B>silent <C-E>s/^/<C-R>=escape(b:comment_leader,'\/')<CR>/<CR>:nohlsearch<CR>
noremap <silent> cu :<C-B>silent <C-E>s/^\(\s*\)\V<C-R>=escape(b:comment_leader,'\/')<CR>/\1/e<CR>:nohlsearch<CR>

" ===================================================================
" AUTOCOMMANDS
" ===================================================================
augroup GeneralAutocommands
  autocmd!
  " Auto-reload files when focused
  autocmd FocusGained,BufEnter * silent! checktime
  " Return to last edit position
  autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
augroup END

" ===================================================================
" CUSTOM COMMANDS
" ===================================================================
" Save file with sudo
command! W execute 'w !sudo tee % > /dev/null' <bar> edit!
