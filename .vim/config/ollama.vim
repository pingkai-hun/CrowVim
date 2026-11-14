" ============================================================================
" Vim-Ollama 配置 —— 本地 qwen2.5-coder (Ollama)
" 由 gergap/vim-ollama 使用；用 :Ollama config 可再打开编辑
" ============================================================================

" Ollama 服务地址
let g:ollama_host = 'http://localhost:11434'

" 模型：本机目前只有 qwen2.5-coder:1.5b，补全/编辑/聊天都先指向它。
" 想要更好的聊天/编辑体验，可 `ollama pull qwen2.5-coder:7b` 后改这里的 edit/chat。
let g:ollama_model      = 'qwen2.5-coder:1.5b'   " 代码补全（FIM）
let g:ollama_edit_model = 'qwen2.5-coder:1.5b'   " 自然语言改代码
let g:ollama_chat_model = 'qwen2.5-coder:1.5b'   " 聊天 / review

" Python 环境：用我们自建的 venv（含 httpx / requests / jinja2），不走插件自带 venv
let g:ollama_use_venv = 0
let g:ollama_python_interpreter = expand('$HOME/.vim/ollama-venv/bin/python')

" 触发时机与上下文
let g:ollama_debounce_time = 400   " 停止输入多久后请求补全（毫秒，默认 500）
let g:ollama_context_lines = 40    " 送给模型的上下文行数（默认 30）

" 只在合适的缓冲区里补全（denylist 优先排除）
let g:ollama_completion_allowlist_filetype = []   " 留空=所有类型都启用
let g:ollama_completion_denylist_filetype = ['markdown', 'text', 'gitcommit', 'help', 'qf', 'nerdtree', 'OllamaChat']

" 排错时把 debug 设为 1，日志见 g:ollama_logfile
let g:ollama_debug = 0
let g:ollama_show_llm_request = v:false
