" ============================================================================
" crow#palette —— 把「语义名」解析成当前配色里的颜色（Vim9 script）
" ============================================================================
" 为什么需要它：主题增强（行号、补全菜单、搜索、诊断标志……）如果写死
" gruvbox 的 #ea6962，切换到 catppuccin / tokyonight 时就会花屏。
" 这里把「配色名」映射到对应色板函数，新增配色只需在 Register() 里加一行。
vim9script

import './model.vim' as model

# 脚本局部函数引用表：配色名 → 色板函数
# （Vim9 里调用函数引用必须写 call(f, [])，直接 f() 会被当成未知命令）
var registered: dict<any> = {}

def Register(): void
  registered = {
    'gruvbox-material': model.Gruvbox,
    'catppuccin_mocha': model.CatppuccinMocha,
    'catppuccin': model.CatppuccinMocha,
    'catppuccin_macchiato': model.CatppuccinMacchiato,
    'catppuccin_frappe': model.CatppuccinFrappe,
    'catppuccin_latte': model.CatppuccinLatte,
    'tokyonight': model.TokyoNight,
  }
enddef

# 当前配色的语义色板。没登记过的配色 → gruvbox 色板兜底，
# 同时 known = false，:Doctor 会提示。
export def Palette(): dict<any>
  if empty(registered)
    Register()
  endif
  var name: string = get(g:, 'colors_name', '')
  var known: bool = has_key(registered, name)
  var result: dict<any> = call(known ? registered[name] : model.Gruvbox, [])
  result.known = known
  result.name = name
  return result
enddef

# 取语义名对应颜色；未知名字返回空串
export def Color(name: string): string
  return get(Palette(), name, '')
enddef

# 已登记的配色名（给 :Theme 补全用）
export def Names(): list<string>
  if empty(registered)
    Register()
  endif
  return sort(keys(registered))
enddef
