filetype plugin on " Auto-detect un-labeled filetypes
syntax on " Turn syntax highlighting on
set ai " Sets auto-indentation
set si " Sets smart-indentation
set tabstop=2 " Tab equal 2 spaces (default 4)
set expandtab " Use spaces instead of a tab charater on TAB
set smarttab " Be smart when using tabs
set wrap " Wrap overflowing lines
set incsearch " When searching (/), display results as you type (instead of only upon ENTER)
set smartcase " When searching (/), automatically switch to a case-sensitive search if you use any capital letters
set ttyfast " Boost speed by altering character redraw rates to your terminal

set nocompatible
set ruler
set nonumber autoindent
set ignorecase smartcase incsearch
set hidden nowrap nobackup noswapfile autoread
set wildmenu wildmode=list:longest,full laststatus=2
set encoding=utf8 spelllang=en_us
set backspace=2 scrolloff=4
set shiftwidth=4 tabstop=4
set path+=** gp=grep\ -irn

au FocusGained,BufEnter * silent! checktime " auto reload on focus lost
" go to the position I was when last editing the file
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g'\"" | endif

filetype plugin indent on
syntax enable

nnoremap <C-Right> :bnext<cr>
nnoremap <C-Left> :bprevious<cr>
nnoremap <C-b> :buffers<cr>:buffer
nnoremap <C-q> :copen<cr>

" Personal tabs/spaces settings.
autocmd Filetype make,go,sh setlocal noexpandtab tabstop=4 shiftwidth=4
autocmd Filetype c,cpp,zig setlocal expandtab tabstop=4 shiftwidth=4
autocmd Filetype lua,nix,html,xml,javascript,css setlocal expandtab tabstop=2 shiftwidth=

" External auto-formatters.
autocmd FileType c,cpp setlocal formatprg=clang-format
autocmd FileType go setlocal formatprg=gofmt

" Code commenting - https://stackoverflow.com/a/1676672.
augroup CodeCommenting
    autocmd!
    autocmd FileType c,cpp,go,zig,javascript  let b:comment_leader = '// '
    autocmd FileType sh,ruby,python   let b:comment_leader = '# '
    autocmd FileType conf,fstab       let b:comment_leader = '# '
    autocmd FileType lua,sql          let b:comment_leader = '-- '
    autocmd FileType vim              let b:comment_leader = '" '
augroup END
noremap <silent> cc :<C-B>silent <C-E>s/^/<C-R>=escape(b:comment_leader,'\/')<CR>/<CR>:no
noremap <silent> cu :<C-B>silent <C-E>s/^\(\s*\)\V<C-R>=escape(b:comment_leader,'\/')<CR>

" FZF fuzzy finder integration.
function! FZF()
    let t=tempname()
    silent execute '!fzf --preview=''cat {}'' --multi|awk ''{print $1":1:0"}'' > '.fnamee
    execute 'cfile '.t|redraw!
    call delete(t)
endfunction
nnoremap <C-p> :call FZF()<cr>

" :W sudo saves the file
" (useful for handling the permission-denied error)
command! W execute 'w !sudo tee % > /dev/null' <bar> edit!

" Turn on the Wild menu
set wildmenu
