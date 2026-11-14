" ============================================================================
" :Doctor —— 一键体检（语言服务器 / coc 扩展 / 外部工具 / 主题适配）
" ============================================================================
" 之前排查问题时最痛苦的是：coc 配置里写了路径，但二进制实际不存在，
" coc 只会静默失败。这里把「配置里要求的」和「系统里实际有的」对一遍，
" 结果输出到临时 buffer，方便复制 / 搜索。

if exists('g:loaded_crow_doctor')
    finish
endif
let g:loaded_crow_doctor = 1

" 配置里声明的语言服务器：名字 → 可能的可执行文件（按优先级）
let s:servers = [
            \ ['rust-analyzer',   ['rust-analyzer']],
            \ ['clangd',          ['clangd']],
            \ ['pyright',         ['pyright-langserver', 'pyright', 'basedpyright-langserver']],
            \ ['ruff (格式化)',   ['ruff']],
            \ ['gopls',           ['gopls']],
            \ ['lua-language-server', ['lua-language-server']],
            \ ['vim-language-server', ['vim-language-server']],
            \ ['bash-language-server', ['bash-language-server']],
            \ ['typescript-language-server', ['typescript-language-server']],
            \ ['omnisharp',       ['OmniSharp', 'omnisharp', 'dotnet']],
            \ ]

" 配套的 coc 扩展（coc_global_extensions 里声明的）
let s:extensions = get(g:, 'coc_global_extensions', [])

" 已知但不是 .vimrc 声明的辅助扩展
let s:auxiliary = ['prettier']

function! s:TryNames() abort
    try
        return join(crow#palette#Names(), ', ')
    catch
        return '(主题引擎未加载)'
    endtry
endfunction

function! s:Ok(cond) abort
    return a:cond ? '✔' : '✘'
endfunction

function! s:FindBinary(name) abort
    return exepath(a:name)
endfunction

function! s:Extensions() abort
    let l:root = exists('*stdpath') && has('nvim')
                \ ? stdpath('data') . '/coc/extensions'
                \ : expand('~/.config/coc/extensions')
    let l:dirs = {}
    for l:dir in glob(l:root . '/node_modules/*', 0, 1)
        let l:dirs[fnamemodify(l:dir, ':t')] = 1
    endfor
    return l:dirs
endfunction

" 去掉 JSONC 的 // 注释（只认字符串外的 //）与尾随逗号，得到合法 JSON
function! s:StripJsonc(text) abort
    let l:res = []
    let l:instr = 0
    let l:esc = 0
    for l:line in split(a:text, "\n")
        let l:buf = ''
        let l:i = 0
        let l:n = len(l:line)
        while l:i < l:n
            let l:c = l:line[l:i]
            if l:instr
                let l:buf .= l:c
                if l:esc
                    let l:esc = 0
                elseif l:c ==# '\'
                    let l:esc = 1
                elseif l:c ==# '"'
                    let l:instr = 0
                endif
                let l:i += 1
                continue
            endif
            if l:c ==# '"'
                let l:instr = 1
                let l:buf .= l:c
                let l:i += 1
                continue
            endif
            if l:c ==# '/' && l:i + 1 < l:n && l:line[l:i + 1] ==# '/'
                break
            endif
            let l:buf .= l:c
            let l:i += 1
        endwhile
        call add(l:res, l:buf)
    endfor
    return substitute(join(l:res, "\n"), ',\s*\([}]\)', '\1', 'g')
endfunction

" coc-settings.json 里的 languageserver / 各扩展指定了绝对路径时，
" 检查路径是否真的可执行（最常见的手误：/usr/bin/xxx 不存在）
function! s:CheckConfiguredPaths(lines) abort
    let l:file = expand('~/.vim/coc-settings.json')
    if !filereadable(l:file)
        call add(a:lines, '  ' . s:Ok(0) . ' coc-settings.json 不存在: ' . l:file)
        return
    endif
    let l:json = {}
    try
        let l:json = json_decode(s:StripJsonc(join(readfile(l:file), "\n")))
        call add(a:lines, '  ✔ coc-settings.json 语法正确（' . len(keys(l:json)) . ' 项）')
    catch
        call add(a:lines, '  ✘ coc-settings.json 解析失败: ' . v:exception)
        return
    endtry
    let l:paths = []
    " 1) languageserver.<name>.command（并展开 ~）
    for [l:name, l:conf] in items(get(l:json, 'languageserver', {}))
        if get(l:conf, 'enable', 1) && has_key(l:conf, 'command')
            call add(l:paths, [l:name, expand(l:conf.command)])
        endif
    endfor
    " 2) 任意 "<扩展>.server.path" / "<扩展>.path" 这类绝对路径
    for [l:key, l:value] in items(l:json)
        if type(l:value) != v:t_string
            continue
        endif
        if l:key =~# '\.\(path\|ruffPath\|shellcheckPath\)$' && l:value =~# '^[/~]'
            call add(l:paths, [l:key, expand(l:value)])
        endif
    endfor
    for [l:name, l:path] in l:paths
        let l:exe = executable(l:path)
        call add(a:lines, printf('  %s %-34s %s %s', s:Ok(l:exe), l:name,
                    \ l:path, l:exe ? '' : '（不存在或不可执行！）'))
    endfor
endfunction

function! s:Run() abort
    let l:lines = []
    call add(l:lines, 'Easy-Vim 体检报告  ' . strftime('%Y-%m-%d %H:%M:%S'))
    call add(l:lines, repeat('=', 60))

    " ---- 环境 ----
    call add(l:lines, '')
    call add(l:lines, '【环境】')
    call add(l:lines, '  Vim        ' . v:version . ' (vim9script=' . s:Ok(has('vim9script')) . ')')
    call add(l:lines, '  termguicolors ' . s:Ok(&termguicolors) . '   GUI=' . s:Ok(has('gui_running'))
                \ . '   真彩色(has truecolor)=' . s:Ok(has('termtruecolor') || has('gui_running')))
    call add(l:lines, '  +clipboard ' . s:Ok(has('clipboard')) . '   剪贴板提供者: '
                \ . (exists('g:clipboard') ? '自定义' : (executable('wl-copy') ? 'wl-clipboard' : (executable('xclip') ? 'xclip' : '无'))))
    call add(l:lines, '  终端       ' . (empty($TERM) ? '?' : $TERM) . '  超时 ttimeout=' . &ttimeout)
    call add(l:lines, '  浮窗终端   ' . s:Ok(exists('*popup_create') && exists('*term_start'))
                \ . '（<F7> 用，Vim 内置实现）')
    call add(l:lines, '  插件管理器 vim-plug ' . s:Ok(exists(':PlugStatus') != 0) . '  已装插件数: '
                \ . len(glob(expand('~/.vim/plugged/*'), 0, 1)) . ' 个')

    " ---- 主题 ----
    call add(l:lines, '')
    call add(l:lines, '【主题】')
    try
        call extend(l:lines, map(crow#util#Report(), '"  " . v:val'))
    catch
        call add(l:lines, '  ✘ 主题引擎未加载: ' . v:exception)
    endtry

    " ---- 语言服务器 ----
    call add(l:lines, '')
    call add(l:lines, '【语言服务器可执行文件】')
    for [l:name, l:cands] in s:servers
        let l:found = []
        for l:c in l:cands
            let l:p = s:FindBinary(l:c)
            if !empty(l:p)
                call add(l:found, l:p)
            endif
        endfor
        call add(l:lines, printf('  %s %-26s %s', s:Ok(!empty(l:found)), l:name,
                    \ empty(l:found) ? '未安装（该语言补全/诊断不可用）' : l:found[0]))
    endfor

    " ---- coc ----
    call add(l:lines, '')
    call add(l:lines, '【coc.nvim】')
    call add(l:lines, '  coc 已加载 ' . s:Ok(exists('*coc#rpc#ready')))
    let l:ready = 0
    if exists('*coc#rpc#ready')
        try
            let l:ready = coc#rpc#ready()
        catch
            let l:ready = 0
        endtry
        call add(l:lines, '  coc 服务就绪 ' . s:Ok(l:ready) . '（首次启动需要几秒）')
    endif
    let l:installed = s:Extensions()
    for l:ext in s:extensions
        call add(l:lines, printf('  %s %s', s:Ok(has_key(l:installed, l:ext)), l:ext))
    endfor
    if !empty(l:installed)
        for l:extra in sort(filter(keys(l:installed),
                    \ 'index(s:extensions, v:val) < 0 && index(s:auxiliary, v:val) < 0'))
            call add(l:lines, '  ✔ ' . l:extra . '（额外安装，未在 .vimrc 声明）')
        endfor
    endif
    call s:CheckConfiguredPaths(l:lines)

    " ---- 外部工具 ----
    call add(l:lines, '')
    call add(l:lines, '【外部工具】')
    for [l:name, l:cands] in [['fzf', ['fzf']], ['rg (fzf 搜索)', ['rg']], ['ctags', ['ctags']],
                \ ['dotnet', ['dotnet']], ['python3', ['python3']], ['ollama', ['ollama']],
                \ ['stylua', ['stylua']], ['shfmt', ['shfmt']], ['shellcheck', ['shellcheck']],
                \ ['prettier', ['prettier']]]
        let l:p = ''
        for l:c in l:cands
            let l:p = s:FindBinary(l:c)
            if !empty(l:p)
                break
            endif
        endfor
        call add(l:lines, printf('  %s %-20s %s', s:Ok(!empty(l:p)), l:name, empty(l:p) ? '未安装' : l:p))
    endfor

    " ---- 关键配置自检 ----
    call add(l:lines, '')
    call add(l:lines, '【关键配置】')
    call add(l:lines, '  leader=' . string(get(g:, 'mapleader', '\')))
    call add(l:lines, '  completeopt=' . &completeopt)
    call add(l:lines, '  updatetime=' . &updatetime . 'ms')
    call add(l:lines, '  pumheight=' . &pumheight)
    call add(l:lines, '  Tab 映射=' . maparg('<Tab>', 'i'))
    call add(l:lines, '  fzf 搜索根（项目根）= ' . crow#ProjectRoot())
    call add(l:lines, '  配色可选: ' . s:TryNames() . '   切换: :Theme <名字>')

    execute 'edit' fnameescape('Easy-Vim-Health')
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
    setlocal filetype=text
    silent %delete _
    call setline(1, l:lines)
    setlocal nomodifiable
    normal! gg
endfunction

command! Doctor call s:Run()
