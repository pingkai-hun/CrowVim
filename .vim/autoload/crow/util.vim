" ============================================================================
" crow#util —— 主题增强引擎（Vim9 script）
" ============================================================================
" 用 Vim 9.2 自带的 hlget() / hlset() / hlexists() 读写高亮组，比解析
" `:hi` 的文本输出可靠（不受栏宽、语言、link 影响）。
" 整个文件首次使用时编译一次，之后调用开销极小。
vim9script

import './palette.vim' as palette

# 十六进制颜色统一小写，大小写不同的同一颜色才能正确比较
def Norm(color: string): string
  return color =~# '^#' ? tolower(color) : color
enddef

# 取高亮组当前生效的定义（含 link 信息），未定义返回 {}
def GroupInfo(name: string): dict<any>
  if !hlexists(name)
    return {}
  endif
  var info: list<any> = hlget(name, true)
  return empty(info) ? {} : info[0]
enddef

# 沿 link 链解析到最终组，返回 {'group': 最终组名, 'guifg': 最终前景色}
def Resolve(group: string): dict<any>
  var seen: list<string> = []
  var cur: string = group
  while true
    if index(seen, cur) >= 0
      return {}
    endif
    seen->add(cur)
    var info = GroupInfo(cur)
    if empty(info)
      return {}
    endif
    var link: string = get(info, 'linksto', '')
    if !empty(link)
      cur = link
      continue
    endif
    return {'group': cur, 'guifg': get(info, 'guifg', 'NONE')}
  endwhile
  return {}
enddef

# Vim 内置默认语法色（$VIMRUNTIME/syntax/syncolor.vim，dark 背景）
var VIM_DEFAULTS: dict<string> = {
  'Comment': '#80a0ff', 'Constant': '#ffa0a0', 'Special': '#ffa500',
  'Identifier': '#40ffff', 'Statement': '#ffff60', 'PreProc': '#ff80ff',
  'Type': '#60ff60', 'Underlined': '#80a0ff',
}

# 标准语法组在当前配色下的「默认」前景色：
#   显式定义 → link 目标 → Vim 内置默认色 → 色板同义兜底
# 用于「参照 X 组的颜色给 Y 组上色」，这样切换配色时 Y 组自动跟着变。
def SyntaxForeground(group: string, pal: dict<any>): string
  var target = Resolve(group)
  if !empty(target) && target.guifg !~# '\v^(NONE)?$'
    return Norm(target.guifg)
  endif
  var resolved: string = empty(target) ? group : target.group
  if has_key(VIM_DEFAULTS, resolved)
    return VIM_DEFAULTS[resolved]
  endif
  var fallback: dict<string> = {
    'Comment': 'grey1', 'Constant': 'aqua', 'Special': 'yellow',
    'Identifier': 'blue', 'Statement': 'red', 'PreProc': 'purple',
    'Type': 'yellow', 'Normal': 'fg0', 'Underlined': 'blue',
  }
  return get(pal, get(fallback, group, 'fg0'), '')
enddef

# 色板颜色（已小写）
def PalColor(pal: dict<any>, key: string): string
  return Norm(get(pal, key, ''))
enddef

# ----------------------------------------------------------------------------
# 对外：按当前配色重新计算并应用所有高亮覆盖
# 只改 highlight，不执行 colorscheme，所以可以被 ColorScheme 事件安全重复调用。
# ----------------------------------------------------------------------------
export def ApplyTheme(): void
  var pal = palette.Palette()

  # ---- 1. 语法增强 ----
  # 原则：配色已经定义好的语法组（Rust/Python/C/Go/Vim 的细调色）一律不动，
  # 只补「配色自己漏掉、或被压成和别处同色」的几处，让不同语义能区分开。
  var syn: dict<string> = {}
  var preproc_fg = SyntaxForeground('PreProc', pal)

  # 以下两条只在「配色真的没区分开」时生效（比较前统一小写）。
  #
  # (1) 宏 / 条件编译 PreCondit：gruvbox-material 用 `link PreCondit PreProc`
  #     和 include 系压成同色，tokyonight / catppuccin 直接设成同值。
  var pc = Resolve('PreCondit')
  if !empty(pc) && !empty(get(pc, 'guifg', '')) && tolower(pc.guifg) ==# preproc_fg
    syn['PreCondit'] = PalColor(pal, 'purple')
  endif

  # (2) 常量 Constant：tokyonight 把 Constant / Identifier 都设成 orange，
  #     变量和字面量分不清；换成 aqua 与变量区分。
  var ident_fg = SyntaxForeground('Identifier', pal)
  var const_fg = SyntaxForeground('Constant', pal)
  if !empty(const_fg) && const_fg ==# ident_fg
    syn['Constant'] = PalColor(pal, 'aqua')
  endif

  var valid: list<any> = []
  for [group, color] in items(syn)
    if !empty(color) && hlexists(group)
      valid->add({'name': group, 'guifg': color})
    endif
  endfor
  if !empty(valid)
    hlset(valid)
  endif

  # (3) Todo：gruvbox-material 用的是 `gui=reverse,bold guifg=blue guibg=bg0`，
  #     在透明背景 + truecolor 下会变成「蓝底浅字」的刺眼反色块。
  #     凡是配色给 Todo 用了 reverse，就改成「背景色底 + 黄色字」的正常样式。
  var todo = GroupInfo('Todo')
  if !empty(todo) && type(get(todo, 'gui', 0)) == v:t_dict && has_key(todo.gui, 'reverse')
    hlset([{'name': 'Todo', 'guifg': PalColor(pal, 'bg0'), 'guibg': PalColor(pal, 'yellow'),
          \ 'gui': {'bold': true}, 'cterm': {'bold': true}}])
  endif

  # ---- 2. UI：透明背景下的可读性 ----
  # hlset() 的属性写法：'gui' 必须传「属性字典」（True 表示启用）；
  # 传字符串 'NONE'/'bold' 会直接 E715，这点和 `:hi` 命令不同。
  var C = (key: string) => PalColor(pal, key)
  var BOLD: dict<bool> = {'bold': true}
  var ITALIC: dict<bool> = {'italic': true}
  var ui: list<any> = [
    {'name': 'LineNr', 'guifg': C('bg5'), 'guibg': 'NONE'},
    {'name': 'CursorLineNr', 'guifg': C('yellow'), 'guibg': 'NONE', 'gui': BOLD},
    {'name': 'CursorLine', 'guibg': 'NONE', 'gui': {}},
    # WinSeparator 较新；catppuccin 只定义了 VertSplit，这里两个都上，哪个生效用哪个
    {'name': 'WinSeparator', 'guifg': C('bg3'), 'guibg': 'NONE'},
    {'name': 'VertSplit', 'guifg': C('bg3'), 'guibg': 'NONE', 'gui': {}},
    {'name': 'Search', 'guifg': C('bg0'), 'guibg': C('yellow'), 'gui': {}},
    {'name': 'IncSearch', 'guifg': C('bg0'), 'guibg': C('orange'), 'gui': BOLD},
    {'name': 'CurSearch', 'guifg': C('bg0'), 'guibg': C('orange'), 'gui': BOLD},
    {'name': 'MatchParen', 'guifg': C('bg0'), 'guibg': C('aqua'), 'gui': BOLD},
    {'name': 'Visual', 'guifg': 'NONE', 'guibg': C('bg3')},
    {'name': 'Pmenu', 'guifg': C('fg0'), 'guibg': C('bg1')},
    {'name': 'PmenuSel', 'guifg': C('bg0'), 'guibg': C('blue'), 'gui': BOLD},
    {'name': 'PmenuSbar', 'guibg': C('bg1')},
    {'name': 'PmenuThumb', 'guibg': C('grey0')},
    {'name': 'NormalFloat', 'guifg': C('fg0'), 'guibg': C('bg0')},
    # 浮动窗口边框：coc 的 hover / 补全文档 / 签名提示都用它
    {'name': 'FloatBorder', 'guifg': C('grey0'), 'guibg': C('bg0')},
    {'name': 'FloatTitle', 'guifg': C('blue'), 'guibg': C('bg0'), 'gui': BOLD},
    {'name': 'FloatShadow', 'guibg': C('bg0')},
    # 诊断标志只染颜色，不铺底色（保持透明），符号列宽度见 coc-settings
    {'name': 'RedSign', 'guifg': C('red'), 'guibg': 'NONE'},
    {'name': 'YellowSign', 'guifg': C('yellow'), 'guibg': 'NONE'},
    {'name': 'BlueSign', 'guifg': C('blue'), 'guibg': 'NONE'},
    {'name': 'PurpleSign', 'guifg': C('purple'), 'guibg': 'NONE'},
    {'name': 'CocErrorSign', 'guifg': C('red'), 'guibg': 'NONE'},
    {'name': 'CocWarningSign', 'guifg': C('yellow'), 'guibg': 'NONE'},
    {'name': 'CocInfoSign', 'guifg': C('blue'), 'guibg': 'NONE'},
    {'name': 'CocHintSign', 'guifg': C('aqua'), 'guibg': 'NONE'},
    # AI 幽灵文本：比注释还淡一档，明确「只是建议」
    {'name': 'OllamaSuggestion', 'guifg': C('grey1'), 'guibg': 'NONE', 'gui': ITALIC},
  ]
  # 逐个 hlset：某个组在本机不存在或属性不被接受时，不至于整体失败。
  # 注意 hlexists() 对「只设了 term=/cterm= 属性、没有颜色」的组会返回 0，
  # 所以这里不用它过滤，而是直接尝试，报错就跳过（保持安静，不刷屏）。
  for item in ui
    try
      hlset([item])
    catch
    endtry
  endfor
enddef

# ----------------------------------------------------------------------------
# 半透明背景
# ----------------------------------------------------------------------------
# 把「该透出终端背景」的组清掉底色；但补全菜单 / 浮动窗口必须保持实色，
# 否则半透明浮窗叠在文字上会糊成一片，根本看不清。
export def Transparent(): void
  # 这些组如果本来就有底色，全部改回 NONE
  for group in ['Normal', 'NormalNC', 'SignColumn', 'LineNr', 'CursorLineNr',
    \ 'LineNrAbove', 'LineNrBelow', 'CursorLine', 'CursorLineSign', 'CursorLineFold',
    \ 'FoldColumn', 'EndOfBuffer', 'ColorColumn', 'StatusLineNC', 'TabLineFill']
    var info = GroupInfo(group)
    if empty(info) || empty(get(info, 'guibg', ''))
      continue
    endif
    if group ==# 'ColorColumn'
      continue  # 标尺列需要一点底色才看得见，保留
    endif
    try
      hlset([{'name': group, 'guibg': 'NONE'}])
    catch
    endtry
  endfor

  # 显式保证「弹窗类」不透明（顺带统一圆角边框的颜色来源）
  var pal = palette.Palette()
  var solid: list<any> = [
    {'name': 'Pmenu', 'guibg': PalColor(pal, 'bg1')},
    {'name': 'PmenuSbar', 'guibg': PalColor(pal, 'bg1')},
    {'name': 'NormalFloat', 'guibg': PalColor(pal, 'bg1')},
    {'name': 'FloatBorder', 'guibg': PalColor(pal, 'bg1')},
    {'name': 'PmenuBorder', 'guifg': PalColor(pal, 'grey0'), 'guibg': PalColor(pal, 'bg1')},
    {'name': 'PmenuShadow', 'guibg': PalColor(pal, 'bg0')},
  ]
  for item in solid
    try
      hlset([item])
    catch
    endtry
  endfor
enddef

# ----------------------------------------------------------------------------
# 状态栏：圆角胶囊 + 半透明配色（airline 调色板补丁）
# ----------------------------------------------------------------------------
# 由 g:airline_theme_patch_func 在 airline 每次载入主题时调用。
# palette 形如 {'normal': {'airline_a': [fg, bg, ctermfg, ctermbg, attr], ...}, ...}
# 每个模式都要改（normal / insert / visual / replace / commandline / inactive）。
export def PatchAirlinePalette(airline_palette: dict<any>): void
  var pal = palette.Palette()
  var blue = PalColor(pal, 'blue')
  var ink = PalColor(pal, 'bg0')
  var fg = PalColor(pal, 'fg0')
  var muted = PalColor(pal, 'grey2')
  if empty(blue) || empty(ink)
    return
  endif

  # 分段与上色（对应 crow#StatuslineSetup）：
  #   a = 胶囊的左端：E0B6 + 空格。guifg=胶囊色、guibg=透明，
  #       半圆填色、外侧透明 → 正好是胶囊的左圆头。
  #   b = 模式文字：实色底（胶囊主体）
  #   c / z = 文件名与位置：透明背景
  # 所有 sep 都为空，因此不会出现多余的圆头或错位。
  for [mode, sections] in items(airline_palette)
    if type(sections) != v:t_dict || mode ==# 'accents'
      continue
    endif
    var inactive = mode ==# 'inactive'
    var accent = blue
    if inactive
      accent = muted
    elseif mode ==# 'insert'
      accent = PalColor(pal, 'green')
    elseif mode ==# 'visual'
      accent = PalColor(pal, 'purple')
    elseif mode ==# 'replace'
      accent = PalColor(pal, 'red')
    elseif mode ==# 'commandline'
      accent = PalColor(pal, 'orange')
    endif

    # a：只有圆头字形着色（前景 = 胶囊色），背景透明
    if has_key(sections, 'airline_a')
      sections.airline_a = [accent, 'NONE', '', '', '']
    endif
    # b：胶囊主体，实色底
    if has_key(sections, 'airline_b')
      sections.airline_b = inactive ? [muted, 'NONE', '', '', '']
                                   : [ink, accent, '', '', 'bold']
    endif
    # 数据段：透明背景
    for key in ['airline_c', 'airline_x', 'airline_z']
      if has_key(sections, key)
        sections[key] = [fg, 'NONE', '', '', '']
      endif
    endfor
    if has_key(sections, 'airline_y')
      sections.airline_y = [muted, 'NONE', '', '', '']
    endif
  endfor
enddef

# `:Doctor` 用：报告配色适配情况与关键组的最终颜色
export def Report(): list<string>
  var pal = palette.Palette()
  var lines: list<string> = []
  lines->add('配色: ' .. get(g:, 'colors_name', '<none>')
    .. (pal.known ? '  （已登记 → 主题增强颜色已适配）' : '  （未登记 → 使用 gruvbox 色板兜底）'))
  for group in ['Normal', 'Comment', 'Identifier', 'Function', 'Type', 'Constant',
    \ 'Pmenu', 'PmenuSel', 'Visual', 'CursorLineNr', 'OllamaSuggestion']
    var info = GroupInfo(group)
    if empty(info)
      lines->add(printf('  %-16s <未定义>', group))
    else
      var link: string = get(info, 'linksto', '')
      lines->add(printf('  %-16s %-9s %-9s %s', group, get(info, 'guifg', '-'),
        \ get(info, 'guibg', '-'), empty(link) ? '' : '→ ' .. link))
    endif
  endfor
  return lines
enddef
