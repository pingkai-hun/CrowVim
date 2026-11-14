# Crow-Vim

> 一套面向日常开发的 Vim 配置：现代外观、智能补全、调试与 Git 工作流开箱即用。

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Vim](https://img.shields.io/badge/Vim-9.0%2B-019733)

Crow-Vim 是从 **Easy-Vim** 演进而来的个人 Vim 配置，使用 [vim-plug](https://github.com/junegunn/vim-plug) 管理插件，配色以 Catppuccin Mocha 为主，兼顾长时间编码的舒适度与中文显示。

## ✨ 特性

- 🎨 **Catppuccin Mocha** 主配色，附带 Gruvbox Material、TokyoNight 备用主题，支持一键切换
- 🧠 **coc.nvim 智能补全**：LSP、代码诊断、重命名、代码操作
- 🐛 **Vimspector 图形化调试**：断点、单步、变量查看
- 📁 **NERDTree + Vista**：文件树与代码大纲（基于 LSP，比 ctags 更准确）
- 🔍 **fzf / ripgrep**：秒级文件定位与全文搜索
- 🖥️ **浮动终端**：Neovim 用 floaterm，Vim 用内置终端浮窗
- 🌈 **rainbow 括号高亮 + airline 状态栏 + startify 启动页**
- 🤖 **本地 AI 补全**：基于 Ollama（`vim-ollama`，可选）
- 🇨🇳 针对中文优化的补全弹窗宽度、命令行补全与状态栏分段

## 📦 依赖

| 依赖 | 说明 |
| --- | --- |
| `vim` 9.0+ | 需要 `+terminal`、`+python3`（可选） |
| `git` | 插件安装 |
| `nodejs` / `npm` | coc.nvim 运行环境 |
| `ripgrep` | `<leader>/` 全文搜索 |
| `ctags` | Tagbar 备用大纲 |
| `python3` | Vimspector / Ollama 补全 |
| `fzf` | 由 vim-plug 自动安装 |

Arch / CachyOS 一次装齐：

```bash
sudo pacman -S --needed git nodejs npm ripgrep ctags python python-pynvim
```

## 🚀 安装

### 方式一：作为 `~/.vim` 使用（推荐）

```bash
git clone https://github.com/pingkai-hun/Crow-Vim.git ~/.vim
ln -sf ~/.vim/.vimrc ~/.vimrc
vim +PlugInstall +qall
```

### 方式二：直接复制

```bash
git clone https://github.com/pingkai-hun/Crow-Vim.git ~/Crow-Vim
cp ~/Crow-Vim/.vimrc ~/.vimrc
cp -r ~/Crow-Vim/.vim/{config,autoload,plugin,after,coc-settings.json} ~/.vim/
vim +PlugInstall +qall
```

> 安装前建议先备份原有配置：`mv ~/.vimrc ~/.vimrc.bak`、`mv ~/.vim ~/.vim.bak`。

首次启动后执行 `:PlugInstall` 安装插件；coc 扩展可用 `:CocInstall coc-json coc-pyright coc-go` 等按需安装。

## 📂 目录结构

```
Crow-Vim/
├── .vimrc                     # 主配置（基础设置、插件、键位、主题）
└── .vim/
    ├── coc-settings.json      # coc.nvim 语言服务器与扩展配置
    ├── config/
    │   ├── crow.vim           # 自定义函数（项目搜索、终端、对话窗、Doctor）
    │   └── ollama.vim         # 本地 AI 补全（可选）
    ├── autoload/crow/         # 配色、模型、工具函数
    ├── plugin/crow_doctor.vim # :Doctor 体检命令
    └── after/ftplugin/        # Vim / Rust 文件类型微调
```

## ⌨️ 常用键位

Leader 键为 **空格**。

| 键位 | 功能 |
| --- | --- |
| `<leader>w` / `<leader>wq` / `<leader>q` | 保存 / 保存退出 / 退出 |
| `<leader>sr` / `<leader>sc` | 重载配置 / 编辑配置 |
| `<leader>n` / `<leader>nf` | 文件树开关 / 定位当前文件 |
| `<leader>p` / `<leader>b` | 查找文件 / 切换缓冲区 |
| `<leader>/` / `<leader>R` | 全文搜索 / 在项目根目录搜索 |
| `<leader>/` `*` | 搜索光标下单词（`<leader>*`） |
| `<F8>` / `<leader>wa` | 代码大纲与当前符号 |
| `<leader>rn` / `<leader>ac` | 重命名 / 代码操作 |
| `<F5>` `F9` `F10` `F11` `F12` | 调试：继续 / 断点 / 单步跳过 / 步入 / 步出 |
| `<leader>dq` / `<leader>dr` | 停止 / 重启调试 |
| `<F7>` / `<leader>tt` | 终端浮窗 / 在项目根目录开终端 |
| `<F6>` | 用 Python 运行当前文件 |
| `<leader>os` / `<leader>od` / `<leader>oN` | 保存 / 停止 / 恢复会话 |
| `<leader>D` | 运行 `:Doctor` 环境体检 |
| `<leader>h` | 取消搜索高亮 |

## 🎨 主题切换

默认 Catppuccin Mocha。配置中已内置切换命令（见 `.vimrc` 的「主题切换」小节），也可手动：

```vim
:colorscheme catppuccin_mocha
:Theme tokyonight
```

## 📄 许可证

本项目基于 [MIT License](LICENSE) 开源。

Copyright © 2026 White-Crow-Bug

## 🙏 致谢

- 前身项目 Easy-Vim
- [vim-plug](https://github.com/junegunn/vim-plug)、[coc.nvim](https://github.com/neoclide/coc.nvim)、[Catppuccin](https://github.com/catppuccin/vim) 及所有插件作者
