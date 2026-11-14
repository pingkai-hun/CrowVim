" ============================================================================
" vim / vimrc 语言增强
" ============================================================================
" Vim 自带的 syntax/vim.vim 用一条规则匹配所有 $VAR（vimEnvvar），
" gruvbox-material 又把它 link 成紫色 —— 于是 $HOME/.vim 这种路径里
" 每个变量都亮成一片。这里把「已定义的变量」恢复成正文色，
" 「未定义的」保持醒目红色：看 .vimrc 时，真正要注意的地方才突出。
if get(b:, 'current_syntax', '') ==# 'vim' && exists('*hlset')
    syn clear vimEnvvar
    " 已定义 / 未定义的区分靠 coc 的 vim-language-server 来做（它会标未定义），
    " 语法层只负责让变量名不再抢眼。
    syn match vimEnvvar '\$\I\i*'
    syn match vimEnvvar '\${\I\i*}'
    hi def link vimEnvvar Normal
    " 分节标题（====）压暗，文件头注释不抢视线
    syn match vimSectionTitle '^"\s*[=#-]\{4,}\s*$'
    hi def link vimSectionTitle Comment
endif

setlocal shiftwidth=4 softtabstop=4 expandtab
setlocal commentstring=\"%s
setlocal foldmethod=marker

" 正在编辑 vim 配置时的快捷调试（只在 vim 文件里生效）
nnoremap <buffer> <silent> <leader>x :<C-u>execute 'source' expand('%:p')<CR>
nnoremap <buffer> <silent> <leader>X :<C-u>source $MYVIMRC<CR>
