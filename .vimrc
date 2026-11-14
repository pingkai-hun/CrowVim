" ============================================================================
" Crow-Vim - 配置 Beta v0.2.1 26/11/4 20:45:17
" Copyright © 2026 White-Crow-Bug:(
" one line to give the program's name and a brief description

"Permission is hereby granted, free of charge, to any person obtaining
"a copy of this software and associated documentation files (the "Software"),
"to deal in the Software without restriction, including without limitation
"the rights to use, copy, modify, merge, publish, distribute, sublicense,
"and/or sell copies of the Software, and to permit persons to whom the
"Software is furnished to do so, subject to the following conditions:

"The above copyright notice and this permission notice shall be included
"in all copies or substantial portions of the Software.

"THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
"EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
"OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
"DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
"OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

" ============================================================================

" ============================================================================
" 基础设置
" ============================================================================
set nocompatible
filetype plugin indent on
syntax on

set number                      " 行号
set relativenumber              " 相对行号
"set cursorline                  " 高亮当前行
set scrolloff=5                 " 滚动边距

set expandtab                   " Tab 转空格
set tabstop=4                   " Tab 宽度
set shiftwidth=4                " 缩进宽度
set softtabstop=4               " 退格删除空格
set autoindent                  " 自动缩进
set breakindent                 " 折行时保持缩进层级（长行更易读）
set linebreak                   " 按单词折行，不把单词劈两半
set wrap                        " 长行折行

set ignorecase                  " 搜索忽略大小写
set smartcase                   " 智能大小写
set incsearch                   " 实时搜索
set hlsearch                    " 高亮所有匹配（<leader>h 临时关闭）
set hidden                      " 允许隐藏缓冲区
set mouse=a                     " 启用鼠标
set mousemodel=popup            " 右键出菜单

set wildmenu                    " 命令补全菜单
set wildignorecase              " 忽略大小写
set wildmode=longest:full,full  " 先补最长公共前缀，再逐项选择
set wildoptions=pum             " 命令补全用 popup 菜单（Vim 9 新增，多列显示）
set showcmd                     " 显示输入的命令
set history=1000                " 命令历史
set ttimeout ttimeoutlen=10     " Esc 立即生效（避免 1 秒延迟）
set timeoutlen=500              " 按键序列超时

set clipboard=unnamedplus       " 与系统剪贴板互通
set updatetime=300              " 更快的 CursorHold 响应（补全/诊断）
set splitright splitbelow       " 新窗口默认在右/下
set pumheight=12                " 补全弹窗最多 12 行
set pumwidth=20                 " 补全弹窗最小宽度（中文标签不被截断）
set completeopt=menu,menuone,popup,noinsert,noselect
                                " 菜单 + 即时有候选 + 文档弹窗；
                                " 不自动选中、不自动插入（防误触）
set shortmess+=c                " 补全时少刷状态栏消息
set display+=lastline           " 超长行折行显示而不是 @
set noswapfile                  " 不生成 .swp
set undofile                    " 持久化撤销
set undodir=~/.vim/undo         " 撤销文件目录
silent! call mkdir(expand('~/.vim/undo'), 'p')
set nrformats-=octal            " <C-a>/<C-x> 不把 0 开头当八进制
set termguicolors               " 真彩色（放 colorscheme 之前）
set noshowmode                  " 状态栏已显示模式，不重复提示
set virtualedit=block           " 可视块模式可越过行尾（对齐表格用）
set backupdir=~/.vim/backup
silent! call mkdir(expand('~/.vim/backup'), 'p')
set diffopt+=internal,algorithm:patience,linematch:60   " 更准的 diff
set encoding=utf-8
scriptencoding utf-8

" ============================================================================
" 插件管理器 (vim-plug)
" ============================================================================
" leader 必须在插件加载之前设置：vim-ollama 等在加载时就用 <leader> 建映射，
" 放在后面会让它们的映射落到默认的反斜杠 leader 上。
let mapleader = " "

" coc 全局扩展要在 coc 加载前定义（否则自动安装不生效）
" 说明：本机已装 coc-omnisharp（.NET），这里一并声明，换机器时会自动装回来。
if !exists('g:coc_global_extensions')
    let g:coc_global_extensions = [
        \ 'coc-rust-analyzer',
        \ 'coc-pyright',
        \ 'coc-clangd',
        \ 'coc-sh',
        \ 'coc-lua',
        \ 'coc-json',
        \ 'coc-yaml',
        \ 'coc-snippets',
        \ 'coc-omnisharp',
        \ ]
endif

" vim-polyglot：Rust 交给显式安装的 rust.vim；autoindent/sensible 也让给本文件。
" 另外 polyglot 的语法整体被降到 $VIMRUNTIME 之后（见下方「polyglot 让位」），
" 所以 TS / Vue / TOML / Zig 等优先使用 Vim 9.2 自带的新版语法。
let g:polyglot_disabled = ['rust', 'autoindent', 'sensible']

" --- vim-ollama：必须在插件加载之前设置，插件用 if !exists() 填默认值 ---
if filereadable(expand('~/.vim/config/ollama.vim'))
    execute 'source' expand('~/.vim/config/ollama.vim')
endif
" 不让 ollama 抢 Tab：它记录「原始 Tab 映射」时 coc 的映射还没建立，会把
" coc 弄丢。Tab 的仲裁由本文件下方 coc 区块统一处理。
let g:ollama_no_tab_map = 1

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo ' . data_dir . '/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" ---- 状态栏：圆角 + 半透明（必须在 airline 加载之前设好分段）----
" 细节见 ~/.vim/config/crow.vim 的「状态栏」区块。这里的原因很简单：
" airline 在启动时一次性构建 section 字符串，插件加载后再改 g:airline_section_*
" 会让 :AirlineRefresh 重建出错乱的分隔符。
let g:crow_rounded_statusline = get(g:, 'crow_rounded_statusline', 1)
let g:crow_transparent = get(g:, 'crow_transparent', 1)

call plug#begin()

" ---- 核心：必须最先加载 ----
" coc.nvim 排第一个：它要接管 completeopt 与插入模式映射，
" 排在 vim-ollama / auto-pairs 之后容易被它们的自动命令干扰。
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" ---- 配色 ----
Plug 'catppuccin/vim', { 'as': 'catppuccin' }   " 主配色（catppuccin_mocha，自带 airline 主题）
Plug 'sainnhe/gruvbox-material'                 " 备用（暖色低对比）
Plug 'ghifarit53/tokyonight-vim'                " 备用（:Theme tokyonight）

" ---- 语法 / 高亮 ----
Plug 'sheerun/vim-polyglot'          " 语言包（已禁用 rust；语法让位给 Vim 自带）
Plug 'luochen1990/rainbow'           " 括号彩虹
Plug 'psliwka/vim-smoothie'          " 平滑滚动

" ---- 界面 ----
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'preservim/nerdtree'
Plug 'liuchengxu/vista.vim'          " 代码大纲（走 coc/LSP，比 tagbar 准）
Plug 'preservim/tagbar'              " ctags 备份（非 LSP 语言时用）
Plug 'mhinz/vim-startify'
Plug 'yggdroot/indentline'

" ---- 编辑增强 ----
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-obsession'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'jiangmiao/auto-pairs'          " 自动配对括号
Plug 'junegunn/vim-easy-align'       " ga 对齐
Plug 'godlygeek/tabular'             " EasyAlign 的底层对齐引擎
Plug 'honza/vim-snippets'            " 片段库（coc-snippets 读取）
Plug 'mattn/emmet-vim'               " HTML/CSS 缩写展开

" ---- 补全菜单：圆角边框 + 轻微透明（Vim 9.2 的 pumborder/pumopt）----
" border:round 让补全菜单四角变圆，margin 给左右各留一格呼吸感，
" shadow 在右下画阴影；opacity 只对菜单本身生效，不依赖终端透明度。
if exists('+pumborder')
    set pumborder=round,margin,shadow
endif
if exists('+pumopt')
    set pumopt=border:round,margin,opacity:88
endif

" ---- 搜索 / 文件 ----
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" ---- Git ----
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

" ---- 键位提示 / 调试 / 终端 ----
Plug 'liuchengxu/vim-which-key'
Plug 'voldikss/vim-floaterm'         " Neovim 用；Vim 里由 <F7> 内置浮窗代替
Plug 'puremourning/vimspector'

" ---- 语言支持 ----
Plug 'fatih/vim-go'
Plug 'rust-lang/rust.vim'

" ---- 本地 AI 补全（Ollama），配置见 ~/.vim/config/ollama.vim ----
Plug 'gergap/vim-ollama'
call plug#end()

" ============================================================================
" Go：vim-go 管专属命令，coc/gopls 管补全诊断（不要两套抢）
" ============================================================================
" 分工：
"   · 补全 / 诊断 / 重命名 / gd、gy、gi、gr、K  →  coc + gopls
"     （gopls 由 ~/.vim/coc-settings.json 的 languageserver 启动，路径 /usr/bin/gopls）
"   · :GoBuild / :GoRun / :GoTest / :GoAddTags / :GoDebug …  →  vim-go
" 因此这里关掉 vim-go 会覆盖同名按键的映射，并关掉它自己的保存时格式化，
" 保存格式化统一由下方 augroup 里的 crow#CocFormatOnSave() 执行一次。
let g:go_gopls_enabled = 0                 " 不要再起一个 gopls，LSP 统一由 coc 负责
let g:go_def_mapping_enabled = 0          " 不覆盖 gd / gD
let g:go_doc_keywordprg_enabled = 0       " K 交给 coc 悬浮文档
let g:go_doc_popup_window = 1             " :GoDoc 用悬浮窗
let g:go_fmt_autosave = 0                 " 保存不重复跑 gopls
let g:go_imports_autosave = 0
let g:go_metalinter_autosave = 0
let g:go_fmt_command = 'goimports'        " 手动 :GoFmt 时顺便整理 import
let g:go_imports_mode = 'goimports'
let g:go_metalinter_command = 'staticcheck'
let g:go_list_type = 'quickfix'
let g:go_test_show_name = 1               " 测试输出带 TestXxx 名字
let g:go_test_timeout = '60s'
let g:go_term_mode = 'split'              " :GoRun / :GoTest 在下方分屏跑
let g:go_term_enabled = 1
let g:go_addtags_transform = 'snakecase'  " json:"user_name" 风格

" vim-go 自带语法高亮默认大多关闭，这里打开常用的几项
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_function_parameters = 1
let g:go_highlight_operators = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_generate_tags = 1
let g:go_highlight_variable_declarations = 1
let g:go_highlight_variable_assignments = 1

" Go 文件专属快捷键（<leader>g 前缀，只在 go buffer 里生效）
augroup crow_go
    autocmd!
    autocmd FileType go nnoremap <buffer> <leader>gb :GoBuild<CR>
    autocmd FileType go nnoremap <buffer> <leader>gr :GoRun<CR>
    autocmd FileType go nnoremap <buffer> <leader>gt :GoTest<CR>
    autocmd FileType go nnoremap <buffer> <leader>gT :GoTestFunc<CR>
    autocmd FileType go nnoremap <buffer> <leader>gc :GoCoverageToggle<CR>
    autocmd FileType go nnoremap <buffer> <leader>gv :GoVet<CR>
    autocmd FileType go nnoremap <buffer> <leader>gl :GoMetaLinter<CR>
    autocmd FileType go nnoremap <buffer> <leader>ga :GoAddTags<CR>
    autocmd FileType go nnoremap <buffer> <leader>gA :GoRemoveTags<CR>
    autocmd FileType go nnoremap <buffer> <leader>gD :GoDebugStart<CR>
    autocmd FileType go nnoremap <buffer> <leader>gX :GoDebugStop<CR>
augroup END

" ============================================================================
" polyglot 让位：Vim 自带语法优先
" ============================================================================
" polyglot 会把子模块插到 runtimepath 中间，按扩展名（*.rs 等）判断，
" 会顶掉 Vim 9.2 自带的新语法。这里把它挪到 $VIMRUNTIME 之后：
" 系统自带语法优先，系统没有的语言（jsx、solidity …）仍由 polyglot 兜底。
function! s:DeprioritizePolyglot() abort
    let l:rtp = split(&runtimepath, ',')
    let l:rv = ''
    for l:item in l:rtp
        if fnamemodify(l:item, ':t') ==# 'vim-polyglot' && l:item !~# '/after$'
            let l:rv = l:item
            break
        endif
    endfor
    if empty(l:rv)
        return
    endif
    call filter(l:rtp, 'v:val !=# l:rv')
    " 找到 $VIMRUNTIME（/usr/share/vim/vim92）的位置，插到它后面
    let l:idx = -1
    for l:i in range(len(l:rtp))
        if fnamemodify(l:rtp[l:i], ':p:h:t') ==# 'vim' || l:rtp[l:i] =~# '[/\\]vim9[0-9]$'
            if isdirectory(l:rtp[l:i] . '/syntax') && l:rtp[l:i] !~# 'plugged'
                let l:idx = l:i
            endif
        endif
    endfor
    if l:idx < 0
        call add(l:rtp, l:rv)

    else
        call insert(l:rtp, l:rv, l:idx + 1)
    endif
    let &runtimepath = join(l:rtp, ',')
endfunction
call s:DeprioritizePolyglot()

" ============================================================================
" 插件配置
" ============================================================================

" ---- airline 状态栏 ----
" 分段（模式胶囊 / 文件名 / 位置）与圆角端点由 crow#StatuslineSetup() 在
" 插件加载之前设置好，这里只放不涉及分段结构的开关。
" 注意不要在这里再 let g:airline_section_* —— 会覆盖掉胶囊布局。
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_tab_nr = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#coc#enabled = 1      " 状态栏显示 LSP 诊断
let g:airline#extensions#keymap#enabled = 0
let g:airline#extensions#coc#error_symbol = '✖'
let g:airline#extensions#coc#warning_symbol = '▲'
let g:airline#extensions#whitespace#checks = ['trailing', 'conflicts']
                                " 只查行尾空格 / 冲突标记，缩进检查太吵
let g:airline#extensions#whitespace#symbol = '!'
" 必须为 0：圆角胶囊依赖 section_a 这个「空段」存在，
" skip_empty_sections 会把空段跳过，左圆头的过渡组就没了。
let g:airline_skip_empty_sections = 0

" ---- vista（走 coc/LSP 的代码大纲） ----
let g:vista_default_executive = 'coc'
let g:vista#renderer#enable_icon = 1

" ---- NERDTree ----
let NERDTreeShowHidden = 1
let NERDTreeIgnore = ['\.pyc$', '\.o$', '\.class$', '\~$', '^__pycache__$']
let NERDTreeMinimalUI = 1

" ---- indentline ----
let g:indentLine_char = '│'
let g:indentLine_fileTypeExclude = ['markdown', 'help', 'nerdtree', 'text']
                                " markdown 里会吃掉 `>` 引用符号，必须排除

" ---- tagbar ----
let g:tagbar_width = 30
let g:tagbar_autofocus = 1
let g:tagbar_compact = 1

" ---- vimspector 调试器 ----
let g:vimspector_sidebar_width = 50
let g:vimspector_bottombar_height = 15
let g:vimspector_code_minwidth = 90

" ---- vim-rainbow（括号彩虹） ----
let g:rainbow_active = 1
let g:rainbow_conf = {
\   'guifgs': ['#7AA2F7', '#9D7CD8', '#4FD6BE', '#E0AF68', '#F7768E'],
\   'ctermfgs': ['blue', 'magenta', 'cyan', 'yellow', 'red'],
\   'operators': '_,_',
\   'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
\   'separately': {
\       '*': {},
\       'tex': {
\           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/'],
\       },
\       'lisp': {
\           'guifgs': ['#7AA2F7', '#9D7CD8', '#4FD6BE', '#E0AF68', '#F7768E'],
\       },
\       'vim': {
\           'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold', 'start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold'],
\       },
\       'html': {
\           'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold'],
\       },
\       'css': 0,
\   }
\}

" ---- fzf ----
let g:fzf_layout = { 'down': '~35%' }
let g:fzf_preview_window = ['right:50%', 'ctrl-/']
let g:fzf_history_dir = '~/.local/share/fzf-history'

" ---- floaterm（Neovim） ----
let g:floaterm_keymap_toggle = '<F7>'

" ============================================================================
" 快捷键
" ============================================================================
" 基础操作
nnoremap <leader>w :w<CR>
nnoremap <leader>wq :wq<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>h :nohlsearch<CR>
nnoremap <leader>cd :lcd %:p:h<CR>          " 手动把 cwd 切到当前文件目录
nnoremap <leader>bd :bdelete<CR>            " 关闭当前 buffer（保留窗口）
nnoremap <leader>sr :source $MYVIMRC<CR>    " 重新载入配置
nnoremap <leader>sc :e ~/.vimrc<CR>         " 编辑配置
nnoremap <leader>sC :e ~/.vim/coc-settings.json<CR>
nnoremap <leader>D :Doctor<CR>              " 体检：语言服务器 / coc 扩展 / 配色

" 文件树
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>nf :NERDTreeFind<CR>   " 原 <leader>f 已被 coc-format 占用

" 搜索 (fzf)：默认以当前 cwd 搜；<leader>P / <leader>R 以「项目根」搜
nnoremap <leader>p :Files<CR>
nnoremap <leader>P :call crow#FindAtProjectRoot('files')<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>/ :Rg<CR>
nnoremap <leader>R :call crow#FindAtProjectRoot('rg')<CR>
nnoremap <leader>* :Rg <C-r>=expand('<cword>')<CR><CR>

" 注释
nmap <leader>c gcc
vmap <leader>c gc

" 窗口导航
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" 调试 (vimspector)
nmap <F5> <Plug>VimspectorContinue
nmap <F9> <Plug>VimspectorToggleBreakpoint
nmap <F10> <Plug>VimspectorStepOver
nmap <F11> <Plug>VimspectorStepInto
nmap <F12> <Plug>VimspectorStepOut
nmap <leader>dr <Plug>VimspectorRestart
nmap <leader>dq <Plug>VimspectorStop

" 终端：<F7> 打开/关闭浮动终端（Neovim 用 floaterm，Vim 用内置 popup+term）
if has('nvim')
    nnoremap <F7> :FloatermToggle<CR>
    tnoremap <F7> <C-\><C-n>:FloatermToggle<CR>
elseif exists('*popup_create') && exists('*term_start')
    nnoremap <silent> <F7> :call crow#Floaterm(&shell)<CR>
    tnoremap <silent> <F7> <C-\><C-n>:call crow#Floaterm('')<CR>
else
    nnoremap <F7> :terminal<CR>
endif
nnoremap <leader>tt :call crow#Terminal('')<CR>

" 代码大纲
nnoremap <F8> :Vista coc<CR>
nnoremap <leader>wa :Vista coc<CR>
nnoremap <leader>wt :TagbarToggle<CR>

" 对齐
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" 快捷键提示
nnoremap <silent> <leader> :WhichKey '<Space>'<CR>

" 会话管理（自动存到 ~/.vim/session）
nnoremap <leader>os :Obsess<CR>
nnoremap <leader>od :Obsess!<CR>
nnoremap <leader>oS :execute 'Obsession' crow#SessionFile()<CR>
nnoremap <leader>oN :execute 'source' crow#SessionFile()<CR>

" ============================================================================
" coc 补全与 LSP（coc.nvim 已在上方 plug#end() 加载）
" 说明：
"   · Tab 的仲裁统一放在本区块 —— vim-ollama 那边已用 g:ollama_no_tab_map 让位，
"     coc 自带的 <C-n>/<C-p>/<C-y>/<C-e> 默认映射保持不动；
"   · auto-pairs 在 BufEnter 时会读取下面的 <CR> 全局映射，再把它自己的智能换行
"     接在后面，所以 <CR> 是「coc 确认 → auto-pairs 缩进」串联，不是互相覆盖；
"   · 行为细节（候选来源、触发时机、中文标签）在 ~/.vim/coc-settings.json。
" ============================================================================

" ---- 悬浮文档 / 诊断信息用简体中文 ----
" 系统 LANG=zh_CN.UTF-8 时 coc 传给 LuaLS 的是 "zh_CN"，而 LuaLS 只认 locale/
" 下的 "zh-cn"；它按前两个字母模糊匹配会先撞上 "zh-tw"，于是文档变繁体。
" 这里用 LuaLS 官方环境变量直接指定，coc 启动的语言服务器会继承该值。
let $LLS_LOCALE = 'zh-cn'

" ---- 补全菜单导航：Tab / Shift-Tab / 回车 ----
" 光标前是空白（行首或空格后）→ 插入真正的 Tab，而不是触发补全
function! s:CocCheckBackspace() abort
    let l:col = col('.') - 1
    return !l:col || getline('.')[l:col - 1] =~# '\s'
endfunction

" 菜单开着 → 下一项；接受内联补全；展开/跳片段；空白后 → 真 Tab；否则刷新候选
inoremap <silent><expr> <Tab>
    \ coc#pum#visible() ? coc#pum#next(1) :
    \ coc#inline#visible() ? coc#inline#accept() :
    \ coc#expandableOrJumpable() ?
    \     "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump', ''])\<CR>" :
    \ <SID>CocCheckBackspace() ? "\<Tab>" :
    \ coc#refresh()
inoremap <silent><expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" 回车：菜单开着 → 选中并确认（suggest.noselect 下会自动选第一项）；
" 否则正常换行：<C-g>u 留 undo 断点，coc#on_enter() 让 coc 收尾。
" 注意：auto-pairs 会在本映射后面追加它的智能换行，两者串联生效。
inoremap <silent><expr> <CR>
    \ coc#pum#visible() ? coc#pum#select_confirm() :
    \ "\<C-g>u\<CR>\<C-r>=coc#on_enter()\<CR>"

" 手动唤起补全：Ctrl-Space（终端发出来的就是 <C-@>）
inoremap <silent><expr> <C-@> coc#refresh()

" 候选列表翻页：菜单可见时才接管，否则放行原按键
inoremap <silent><expr> <PageDown> coc#pum#visible() ? coc#pum#scroll(1) : "\<PageDown>"
inoremap <silent><expr> <PageUp>   coc#pum#visible() ? coc#pum#scroll(0) : "\<PageUp>"

" ---- LSP 跳转 ----
" Go 文件里 vim-go 的 ftplugin 会用 <buffer> 覆盖 gd/gD/K（gopls 同样由 coc 起），
" 想统一成 coc 版本就再加：let g:go_def_mapping_enabled = 0 / g:go_doc_keywordprg_enabled = 0
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gD <Plug>(coc-declaration)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" ---- 悬浮文档 / 诊断 ----
nnoremap <silent> K  :call CocActionAsync('doHover')<CR>
nnoremap <silent> gK :call CocActionAsync('documentation')<CR>
nmap <silent> [d <Plug>(coc-diagnostic-prev)
nmap <silent> ]d <Plug>(coc-diagnostic-next)
nnoremap <silent> gl :call CocActionAsync('diagnosticInfo')<CR>

" ---- 重命名 / 代码动作 ----
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>ac <Plug>(coc-codeaction-cursor)

" ---- 悬浮窗口滚动（仅插入模式）----
" 普通/可视模式的 <C-f>/<C-b> 必须留给 vim-smoothie：它用 <unique> 定义这两个键
" 的平滑翻页，这里提前占用会让它的映射静默失败（E227）。插入模式的 <C-f>/<C-b>
" 本身没有默认含义，smoothie 也不占，只在浮窗出现时才接管。
inoremap <silent><nowait><expr> <C-f> coc#float#has_scroll() ? "\<C-r>=coc#float#scroll(1)\<CR>" : "\<Right>"
inoremap <silent><nowait><expr> <C-b> coc#float#has_scroll() ? "\<C-r>=coc#float#scroll(0)\<CR>" : "\<Left>"

" ============================================================================
" 主题 - Catppuccin Mocha（柔和低饱和 / 长时间 coding 护眼）
" ============================================================================
" 主题选项、UI 覆盖、ColorScheme 钩子都在：
"   ~/.vim/config/crow.vim             （ThemeOptions / ThemeSetup / 钩子）
"   ~/.vim/autoload/crow/util.vim      （按当前配色计算所有覆盖颜色）
"   ~/.vim/autoload/crow/palette.vim   （配色 → 语义色板）
" 默认用 catppuccin_mocha；切换其它 flavor：
"   :CrowTheme catppuccin_macchiato / catppuccin_frappe / catppuccin_latte
" 仍然可以用 :Theme 切到 gruvbox-material / tokyonight（airline 不会跟随，
" 想恢复 Catppuccin 的完整观感一律用 :CrowTheme）
if filereadable(expand('~/.vim/config/crow.vim'))
    execute 'source' expand('~/.vim/config/crow.vim')
endif

" airline 主题必须在 colorscheme 之前指定，它会在 ColorScheme 事件里读取。
" catppuccin/vim 自带 airline 主题在 autoload/airline/themes/ 下，
" 名字与配色一一对应（catppuccin_mocha 等）。
let g:airline_theme = 'catppuccin_mocha'
let g:crow_colorscheme = get(g:, 'crow_colorscheme', 'catppuccin_mocha')
" 圆角状态栏的分段要在 airline 加载前设置；这里兜底再调一次（幂等）
call crow#StatuslineSetup()
call crow#ThemeSetup()

" airline 只在「模式变化」或配色切换时才重置状态栏高亮，
" 而 -es / 首次进入时窗口模式未必触发一次，保险起见在启动完成后再刷新一次。
autocmd VimEnter * ++nested silent! AirlineRefresh

" ---- 主题切换 ----
function! s:ThemeComplete(arglead, cmdline, cursorpos) abort
    try
        return filter(crow#palette#Names(), 'stridx(v:val, a:arglead) == 0')
    catch
        return []
    endtry
endfunction
command! -nargs=1 -complete=customlist,s:ThemeComplete Theme execute 'colorscheme' <q-args>

" ============================================================================
" 自动命令
" ============================================================================
" 自动切换目录: 已移除此反模式
" （BufEnter * lcd %:p:h 会不断改 cwd，破坏 :e / 跳转 / terminal。
"  需要时手动 :lcd，或用 <leader>cd）
augroup crow_autocmd
    autocmd!
    " 保存时删除行尾空白（保留光标位置，跳过 markdown 等对空白敏感的类型）
    autocmd BufWritePre * call crow#StripTrailingWhitespace()
    " 保存时用 coc 格式化（rust 由 rustfmt 处理，见下）
    autocmd BufWritePre *.py,*.go,*.c,*.cc,*.cpp,*.h,*.hpp,*.lua,*.sh,*.json,*.yaml,*.yml
                \ call crow#CocFormatOnSave()
    " 重载配置：只有「定义函数 / 命令的脚本」才重新 source 整个 vimrc，
    " 否则每保存一次都在颜色检查上浪费时间
    autocmd BufWritePost ~/.vimrc,~/.vim/config/crow.vim,~/.vim/autoload/crow/*.vim
                \ nested source $MYVIMRC | redraw
    " 窗口大小变化时均分窗口
    autocmd VimResized * wincmd =
augroup END

" Rust 保存时自动格式化（rust.vim 自带开关，保留原设置）
let g:rustfmt_autosave = 1
let g:rust_clip_command = 'wl-copy'

" ============================================================================
" 红队工具 Python 快速开发补丁 于2026/7/9日完成更新
" ============================================================================

" F6: 一键运行当前 Python 脚本（写 PoC / 扫描器专用）
" 先保存，然后在浮动终端里执行（不阻塞编辑器；离开后会话仍在）
nnoremap <F6> :w<CR>:call crow#Floaterm('python3 ' . expand('%:p'))<CR>
" 插入模式下不能直接 :call（会被当作文字输入），先 <C-o> 执行保存再退出
inoremap <F6> <C-o>:w<CR><Esc>:call crow#Floaterm('python3 ' . expand('%:p'))<CR>

" 快速打开 Python 交互环境（测 Payload / 调试代码片段）
nnoremap <leader>py :call crow#Floaterm('python3')<CR>

" 红队常用代码片段快捷键
" 空格+ip → 粘贴一个 Python 格式的 IP 采集模板
nnoremap <leader>ip oimport socket<CR>target = input("Enter target: ")<CR>ip = socket.gethostbyname(target)<CR>print(f"[+] {ip}")<Esc>
" 空格+req → 粘贴一个 requests GET 模板
nnoremap <leader>req oimport requests<CR>url = ""<CR>headers = {"User-Agent": "Mozilla/5.0"}<CR>r = requests.get(url, headers=headers, timeout=5)<CR>print(f"[{r.status_code}] {len(r.text)} bytes")<Esc>

" 行尾空格清理已统一在上方 autocmd 处理，此处不再重复
