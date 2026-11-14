" ============================================================================
" Rust 语言增强
" ============================================================================
" 这个文件在 $VIMRUNTIME/ftplugin/rust.vim 之后加载，解决三个真实问题：

" 1) 缩进断链：rust.vim 会 `runtime! indent/c.vim`，c.vim 设置
"    b:did_indent=1 并启用 cindent；而之后 vim-sleuth 想启用 Rust 的
"    indentexpr 时看到 did_indent 已存在就放弃了 → 缩进实际走 C 的 cindent。
"    c.vim 是按扩展名 *.c/*.h 判断的，对 .rs 本来就不该生效。
if exists('b:did_indent') && get(b:, 'did_indent', 0) && exists('b:undo_indent')
    " 只撤销 c.vim 设置的部分，再重新载入 Vim 自带的 Rust indent
    silent! unlet b:did_indent
    silent! unlet b:cindent_disable
    runtime! indent/rust.vim
endif
if exists('*GetRustIndent') && empty(&l:indentexpr)
    setlocal indentexpr=GetRustIndent(v:lnum)
    setlocal indentkeys=0{,0},0),0],!^F,o,O,<CR>
endif

" 2) 折叠：Vim 自带 rust ftplugin 给 fdl=0，手动 `za` 会提示
"    E490: 没有找到折叠（必须先 :setlocal foldmethod=indent）。
"    这里直接开启语法折叠，vim-smoothie / 大纲体验更一致。
if &l:foldmethod ==# 'manual' && &l:foldlevel == 0
    setlocal foldmethod=syntax
    setlocal foldlevel=99
endif

" 3) 编译/运行：放在 quickfix / 终端里，而不是 `:!cargo run` 卡住编辑器。
"    (原 .vimrc 的 `:!cargo run` 会接管终端，Ctrl-C 后屏幕错乱。)
nnoremap <buffer> <silent> <leader>rr :<C-u>terminal ++curwin cargo run<CR>
nnoremap <buffer> <silent> <leader>rc :<C-u>terminal ++curwin cargo check<CR>
nnoremap <buffer> <silent> <leader>rt :<C-u>terminal ++curwin cargo test<CR>
nnoremap <buffer> <silent> <leader>rf :<C-u>!cargo fmt<CR>

setlocal textwidth=100
