" ============================================================================
" Easy-Vim —— 函数 / 自定义命令（文件名 crow.vim → 函数前缀 crow#）
" ============================================================================
" 由 ~/.vimrc 加载。整份文件有加载保护：重复 source 时直接跳过，
" 这样保存 .vimrc 触发的自动重载不会重复注册 autocmd / 重复定义命令。
" 改动本文件后想立即生效：:let g:loaded_crow = 0 | so ~/.vimrc
" ============================================================================

if exists('g:loaded_crow')
    finish
endif
let g:loaded_crow = 1

" ============================================================================
" 主题
" ============================================================================
" 默认配色是 catppuccin_mocha（见 ~/.vimrc「主题」区块）。
" 下面这些 gruvbox-material 的开关只在切回 gruvbox 时生效，
" 预先设置好是为了 :Theme gruvbox-material / :CrowTheme gruvbox-material 也能得到
" 一致的透明背景与高对比 UI。
function! crow#ThemeOptions() abort
    " 背景半透明交给终端（kitty background_opacity），Vim 侧把背景清成 NONE，
    " 让终端背景透出来。设 g:crow_transparent = 0 可关闭（背景会变回实色）。
    if get(g:, 'crow_transparent', 1)
        let g:gruvbox_material_transparent_background = 1
    endif
    let g:gruvbox_material_background = 'medium'            " hard/medium/soft
    let g:gruvbox_material_foreground = 'material'          " material/mix/original
    let g:gruvbox_material_ui_contrast = 'high'             " 行号/缩进线对比度
    let g:gruvbox_material_sign_column_background = 'none'  " 符号列不加底
    let g:gruvbox_material_menu_selection_background = 'blue'
    let g:gruvbox_material_current_word = 'bold'
    let g:gruvbox_material_visual = 'grey background'
    let g:gruvbox_material_enable_italic = 1
    let g:gruvbox_material_disable_italic_comment = 1       " 注释保持正体，长注释更好读
    let g:gruvbox_material_enable_bold = 1
    let g:gruvbox_material_diagnostic_text_highlight = 1
    let g:gruvbox_material_diagnostic_virtual_text = 'colored'
    let g:gruvbox_material_inlay_hints_background = 'dimmed'
    let g:gruvbox_material_better_performance = 1
    let g:gruvbox_material_show_eob = 0
endfunction

" UI / 语法覆盖：颜色全部由 crow#util（Vim9）按当前配色算出来。
" 只改 highlight、不执行 colorscheme，所以可以被 ColorScheme 事件安全调用。
function! crow#ApplyTheme() abort
    " 注意：Vim9 script 的 export def 用 exists('*') 检测不到，
    "      只能看 has('vim9script')（crow#util 是唯一的 Vim9 模块）。
    if !has('vim9script')
        return
    endif
    try
        call crow#util#ApplyTheme()
    catch
        echohl ErrorMsg
        echomsg 'crow: 主题增强失败: ' . v:exception
        echohl None
    endtry
    " 背景透明必须在配色载入之后做（配色会把 Normal 的底色设成实色），
    " 且要在状态栏配色之前，因为状态栏的半透明颜色是算出来的。
    call crow#Transparent()
    " airline 的颜色由 g:airline_theme_patch_func 负责（见「airline 主题」区块），
    " 配色切换时 airline 会自己重新载入主题并调用它。
endfunction

" ============================================================================
" 半透明背景
" ============================================================================
" Vim 本身不能做「窗口透明度」，真彩色终端里也没有 alpha 通道。做法是：
"   终端（kitty background_opacity 0.82）负责整体透明，
"   Vim 这边把 Normal / SignColumn 等的背景清成 NONE，让终端背景透出来。
" 没做这一步时，Catppuccin 把 Normal 设在 #1e1e2e 上，
" 终端再怎么调透明度，Vim 里看起来都是完全实心的。
function! crow#Transparent() abort
    if !get(g:, 'crow_transparent', 1)
        return
    endif
    if !has('vim9script')
        return
    endif
    try
        call crow#util#Transparent()
    catch
        echohl ErrorMsg
        echomsg 'crow: 透明背景设置失败: ' . v:exception
        echohl None
    endtry
endfunction

" 只在启动时执行一次：设置选项 + 加载默认配色 + 套用覆盖
function! crow#ThemeSetup() abort
    call crow#ThemeOptions()
    if !get(g:, 'crow_colorscheme_loaded', 0)
        let g:crow_colorscheme_loaded = 1
        silent! execute 'colorscheme' get(g:, 'crow_colorscheme', 'gruvbox-material')
    endif
    call crow#ApplyTheme()
endfunction

augroup crow_theme
    autocmd!
    " :colo / :Theme / 任何配色切换后重新套用增强高亮（不会递归）
    autocmd ColorScheme * call crow#ApplyTheme()
augroup END

" ============================================================================
" 状态栏：圆角胶囊 + 半透明配色
" ============================================================================
" 「圆润」分两层实现（Vim 的 'statusline' 只能按字符拼，本身没有圆角）：
"   1. 胶囊端点：U+E0B6 / U+E0B4（Powerline 半圆，Maple Mono NF 自带），
"      套在模式指示和整条线的右端，看起来是一条两端圆头的胶囊；
"   2. 段与段之间一律不插分隔符（不再出现    这种直角三角），
"      只在整条状态栏的最左和最右各放一次圆头，避免多个圆头叠在一起
"
" 颜色不在这里设：全部由 crow#util#PatchAirlinePalette() 按当前配色算，
" 透明模式下数据段不铺底色（胶囊内部透出终端背景），只有模式胶囊是实色。
let s:cap_l = nr2char(0xE0B6)   " 左半圆（胶囊左端）
let s:cap_r = nr2char(0xE0B4)   " 右半圆（胶囊右端）

" 必须在 airline 加载之前调用：airline 只构建一次 section 字符串。
function! crow#StatuslineSetup() abort
    if !get(g:, 'crow_rounded_statusline', 1)
        return
    endif
    let g:airline_powerline_fonts = 1

    " ===== 实现方式（读 airline builder 源码后定的）=====
    " airline 只在「段切换」处插分隔符：
    "   左侧 = g:airline_left_sep，右侧（%= 后）= g:airline_right_sep，
    "   同色相邻段换用 *_alt_sep。没有逐边界配置。
    "
    " 状态栏只有「一个」段却按三种颜色显示，靠的是 airline 的 accent：
    "   'mode' 部件带 accent（__accent_bold），airline 会把它单独着色，
    "   而不产生新的段、也不插分隔符。
    "
    " 所以圆润的方案是：
    "   1. 用 Vim 原生的双色圆头效果——
    "      guifg=胶囊色, guibg=透明 → 半圆填色、另一侧透明，即胶囊端点；
    "   2. 段与段之间不插任何字符（所有 sep 留空），
    "      只在「整条状态栏的最左和最右」各放一次圆头；
    "   3. 中间用留白和颜色区分模式/文件名/位置，不走分隔符。
    "
    " 这样无论内容多长、窗口多窄，都只会出现 1 左 1 右两个圆头，不会错位。
    let g:airline_left_sep = ''
    let g:airline_left_alt_sep = ''
    let g:airline_right_sep = ''
    let g:airline_right_alt_sep = ''

    " a: 左圆头（放在 a 段开头，a 段透明 → 圆头只有字形着色）
    let g:airline_section_a = s:cap_l
    " b: 模式胶囊（实色底）
    let g:airline_section_b = airline#section#create_left(['mode', 'crypt', 'paste', 'spell'])
    " c: 文件名 / LSP（透明）
    let g:airline_section_c = airline#section#create(['%<', 'file', 'readonly', 'coc_status'])
    " x,y: 清零
    let g:airline_section_x = '%{""}'
    let g:airline_section_y = '%{""}'
    " z: 行列位置 + 右圆头收口（放在最后，右侧不会再有多余字符）
    let g:airline_section_z = airline#section#create(['%p%%', 'linenr']) . s:cap_r
endfunction

" ============================================================================
" airline 主题：自己接管颜色
" ============================================================================
" 为什么不能在 ApplyTheme 里 hlset 覆盖 airline 分组：
" airline 每次载入主题都会用它的调色板重新设置 airline_a/c/z…，
" 而配色切换 -> airline#switch_matching_theme -> 载入主题，顺序在我们的
" ColorScheme 钩子之后，覆盖会被冲掉。
" 官方的扩展点就是 g:airline_theme_patch_func(palette)：在 airline
" 设置高亮之前修改调色板。
"
" 各分段对应关系（各模式一致）：
"   airline_a = 第 1 段（模式胶囊）、airline_b = 第 2 段、
"   airline_c = 第 3 段（文件名）… 由 airline#themes#generate_color_map 生成。
function! crow#AirlinePatch(palette) abort
    if !get(g:, 'crow_rounded_statusline', 1) || !has('vim9script')
        return
    endif
    try
        call crow#util#PatchAirlinePalette(a:palette)
    catch
        echohl WarningMsg
        echomsg 'crow: airline 配色调整失败: ' . v:exception
        echohl None
    endtry
endfunction
let g:airline_theme_patch_func = 'crow#AirlinePatch'

" ============================================================================
" 项目根目录
" ============================================================================
let s:MARKERS = [
            \ '.git', '.hg', '.svn', 'Cargo.toml', 'go.mod', 'package.json',
            \ 'pyproject.toml', 'setup.py', 'setup.cfg', 'CMakeLists.txt',
            \ 'Makefile', 'compile_commands.json', '.clangd', 'build.zig',
            \ 'pom.xml', 'build.gradle', 'deno.json', 'mix.exs',
            \ ]

function! s:FindRoot(start) abort
    let l:dir = isdirectory(a:start) ? a:start : fnamemodify(a:start, ':h')
    let l:dir = simplify(resolve(fnamemodify(l:dir, ':p')))
    let l:prev = ''
    while l:dir !=# l:prev
        let l:names = map(copy(s:MARKERS), 'l:dir . "/" . v:val')
        if !empty(filter(l:names, 'getftype(v:val) !=# ""'))
            return l:dir
        endif
        let l:prev = l:dir
        let l:dir = fnamemodify(l:dir, ':h')
    endwhile
    return getcwd()
endfunction

function! crow#ProjectRoot(...) abort
    return s:FindRoot(a:0 ? a:1 : expand('%:p:h'))
endfunction

" ============================================================================
" 浮动终端（Vim 9.2 内置 popup + terminal）
" ============================================================================
" vim-floaterm 只支持 Neovim，Vim 里这里用原生实现：
" 复用同一个终端窗口；关窗时让内部 shell 退出，避免留下僵尸终端。
let s:term_win = 0
let s:term_buf = 0

function! crow#Floaterm(command) abort
    if !exists('*popup_create') || !exists('*term_start')
        echoerr 'crow: 当前 Vim 不支持 popup/terminal，请使用 :terminal'
        return
    endif
    if a:command ==# ''
        " 空命令 = 切换已有终端：可见则隐藏，隐藏则重新显示
        if s:term_win > 0 && win_id2win(s:term_win) > 0
            call popup_hide(s:term_win)
            let s:term_win = 0
        elseif s:term_buf > 0 && bufexists(s:term_buf)
            call s:ShowExisting()
        endif
        return
    endif
    if s:term_win > 0 && win_id2win(s:term_win) > 0
        call popup_close(s:term_win)
    endif
    let l:cmd = split(a:command)
    if empty(l:cmd)
        return
    endif
    let s:term_buf = term_start(l:cmd,
                \ {'cwd': crow#ProjectRoot(), 'term_finish': 'close'})
    call s:ShowExisting()
endfunction

function! s:ShowExisting() abort
    let s:term_win = popup_create(s:term_buf, {
                \ 'title': ' Terminal ',
                \ 'line': 2,
                \ 'col': max([(&columns - s:Width()) / 2, 0]),
                \ 'minwidth': s:Width(),
                \ 'minheight': s:Height(),
                \ 'border': [1, 1, 1, 1],
                \ 'borderhighlight': ['FloatBorder'],
                \ 'highlight': 'NormalFloat',
                \ 'padding': [0, 1, 0, 1],
                \ 'drag': 1,
                \ 'resize': 1,
                \ 'close': 'button',
                \ 'mapping': 0,
                \ 'zindex': 200,
                \ 'filter': function('s:FloatermFilter'),
                \ 'callback': function('s:FloatermClosed'),
                \ })
    call win_execute(s:term_win, 'startinsert')
endfunction

function! s:Width() abort
    return max([min([float2nr(&columns * 0.85), 120]), 40])
endfunction

function! s:Height() abort
    return max([min([float2nr(&lines * 0.55), 34]), 10])
endfunction

function! s:FloatermFilter(winid, key) abort
    " 终端里按 Esc 回到普通模式；普通模式下再按 Esc 或 F7 关闭浮窗
    if a:key ==# "\<Esc>"
        if mode() =~# "^t"
            call win_execute(a:winid, "call feedkeys(\"\\<C-\\>\\<C-n>\", 'n')")
        else
            call popup_close(a:winid)
        endif
        return 1
    endif
    if a:key ==# "\<F7>"
        call popup_close(a:winid)
        return 1
    endif
    return 0
endfunction

function! s:FloatermClosed(id, result) abort
    let s:term_win = 0
    " 浮窗关闭后让 shell 退出，释放进程
    if type(a:result) == v:t_number && a:result > 0
        call term_sendkeys(a:result, "exit\r")
    endif
    let s:term_buf = 0
endfunction

" ============================================================================
" 普通终端（工作目录 = 项目根，方便跑测试 / git）
" ============================================================================
function! crow#Terminal(command) abort
    let l:cmd = empty(a:command) ? [&shell] : split(a:command)
    call term_start(l:cmd, {'cwd': crow#ProjectRoot(), 'curwin': 1})
endfunction

" ============================================================================
" 保存前的清理 / 格式化
" ============================================================================
" 删除行尾空白（保留光标位置；markdown / commit message 跳过）
function! crow#StripTrailingWhitespace() abort
    if &filetype =~# '^\(markdown\|text\|gitcommit\|diff\)$'
        return
    endif
    let l:view = winsaveview()
    silent! keeppatterns %s/\s\+$//e
    call winrestview(l:view)
endfunction

" 保存时用 coc 格式化。rust 由 rust.vim 的 rustfmt_autosave 处理。
function! crow#CocFormatOnSave() abort
    " coc 本身默认就是开机启动，这里的默认值必须跟它一致（1），
    " 否则用户没显式设置 g:coc_start_at_startup 时这里永远提前 return。
    if !get(g:, 'coc_start_at_startup', 1) || &filetype ==# 'rust'
        return
    endif
    " coc#rpc#ready() 只表示 node 进程活着；CocAction 还要求服务初始化完成，
    " 否则会抛 "coc.nvim not ready when invoke CocAction"。
    if !exists('*coc#rpc#ready') || !coc#rpc#ready()
        return
    endif
    if !get(g:, 'coc_service_initialized', 0)
        return
    endif
    " 必须同步：BufWritePre 返回后 Vim 立刻落盘，异步格式化只会把
    " buffer 改脏、磁盘上仍是旧内容。CocAction('format') 等 LSP 返回再写。
    silent! call CocAction('format')
endfunction

" ============================================================================
" 会话
" ============================================================================
function! crow#SessionFile() abort
    let l:dir = substitute(fnamemodify(getcwd(), ':p'), '[\\/:]\+$', '', '')
    let l:dir = fnamemodify(l:dir, ':t')
    let l:host = substitute(hostname(), '[^A-Za-z0-9_-]', '_', 'g')
    call mkdir(expand('~/.vim/session'), 'p')
    return expand('~/.vim/session/') . l:host . '-' . l:dir . '.vim'
endfunction

" ============================================================================
" 消息输出
" ============================================================================
function! crow#Notify(msg, ...) abort
    let l:level = a:0 ? a:1 : 'info'
    let l:hl = get({'info': 'None', 'warn': 'WarningMsg', 'error': 'ErrorMsg'},
                \ l:level, 'None')
    if has('nvim') && exists('*nvim_echo')
        call nvim_echo([[a:msg, l:hl]], v:true, {})
    else
        execute 'echohl' l:hl
        echomsg a:msg
        echohl None
    endif
endfunction

" ============================================================================
" 自定义命令
" ============================================================================
" :Theme —— 切换配色（带补全），例如 :Theme catppuccin_mocha
function! s:ThemeComplete(arglead, cmdline, cursorpos) abort
    try
        return filter(crow#palette#Names(), 'stridx(v:val, a:arglead) == 0')
    catch
        return []
    endtry
endfunction
command! -nargs=1 -complete=customlist,s:ThemeComplete Theme
            \ execute 'colorscheme' <q-args>

" :CrowTheme —— 同时切换配色与 airline 主题（airline 不会自动跟随配色）
"   例子：:CrowTheme catppuccin_mocha / :CrowTheme catppuccin_latte
function! s:CrowThemeComplete(arglead, cmdline, cursorpos) abort
    try
        return filter(crow#palette#Names(), 'stridx(v:val, a:arglead) == 0')
    catch
        return []
    endtry
endfunction
function! s:CrowTheme(name) abort
    execute 'colorscheme' a:name
    let g:crow_colorscheme = a:name
    " airline 主题与配色同名（catppuccin/vim 自带）；不存在则保持不动
    try
        execute 'AirlineTheme' a:name
    catch
        call crow#Notify('airline 没有 "' . a:name . '" 主题，状态栏保持原样', 'warn')
    endtry
    call crow#Notify('配色已切换为 ' . a:name, 'info')
endfunction
command! -nargs=1 -complete=customlist,s:CrowThemeComplete CrowTheme
            \ call s:CrowTheme(<q-args>)

" :ProjectRoot —— cd 到当前文件所在项目的根目录
command! -nargs=? ProjectRoot
            \ execute 'cd' fnameescape(crow#ProjectRoot(<q-args>)) | pwd

" :Floaterm —— 在浮窗里跑一条命令（Vim 内置实现，替代 vim-floaterm）
command! -nargs=+ Floaterm call crow#Floaterm(<q-args>)

" ============================================================================
" 在项目根目录里执行 fzf 搜索（临时 lcd，结束自动切回）
" ============================================================================
function! crow#FindAtProjectRoot(which) abort
    let l:root = crow#ProjectRoot()
    let l:cwd = getcwd()
    execute 'lcd' fnameescape(l:root)
    try
        execute (a:which ==# 'rg' ? 'Rg' : 'Files')
    finally
        execute 'lcd' fnameescape(l:cwd)
    endtry
endfunction
