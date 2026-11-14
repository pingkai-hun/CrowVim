" ============================================================================
" crow#model —— 各配色的语义色板（Vim9 script）
" ============================================================================
" 覆盖的主题代码只说语义名（bg0 / grey1 / red…），由 crow#palette 给出当前
" 配色里的对应颜色。每个配色只维护下面这张小表；值都取自该配色的真实色值。
" 新增配色照着 gruvbox 填一遍即可（至少要有 bg0..bg5、fg0、grey0..grey2、
" red/orange/yellow/green/aqua/blue/purple 这十几项）。
vim9script

# gruvbox-material：medium 背景 + material 前景 + 透明背景
# 注意 transparent_background 下 Normal 的 guibg=NONE，prompt 落在终端背景上，
# 所以前景色用 material（#654735），不能套用 dark 主题的浅色前景。
export def Gruvbox(): dict<string>
  return {
    'bg0': '#282828', 'bg1': '#32302f', 'bg2': '#3c3836', 'bg3': '#45403d', 'bg5': '#5a524c',
    'fg0': '#654735',
    'grey0': '#7c6f64', 'grey1': '#928374', 'grey2': '#a89984',
    'red': '#c14a4a', 'orange': '#c35e0a', 'yellow': '#b47109',
    'green': '#6c782e', 'aqua': '#4c7a5d', 'blue': '#45707a', 'purple': '#945e80',
  }
enddef

# Catppuccin：从 colors/catppuccin_<flavor>.vim 的真实高亮取值
export def CatppuccinMocha(): dict<string>
  return {
    'bg0': '#181825', 'bg1': '#1e1e2e', 'bg2': '#313244', 'bg3': '#45475a', 'bg5': '#585b70',
    'fg0': '#cdd6f4',
    'grey0': '#6c7086', 'grey1': '#9399b2', 'grey2': '#a6adc8',
    'red': '#f38ba8', 'orange': '#fab387', 'yellow': '#f9e2af',
    'green': '#a6e3a1', 'aqua': '#89dceb', 'blue': '#89b4fa', 'purple': '#cba6f7',
  }
enddef

export def CatppuccinMacchiato(): dict<string>
  return {
    'bg0': '#1e2030', 'bg1': '#24273a', 'bg2': '#363a4f', 'bg3': '#494d64', 'bg5': '#5b6078',
    'fg0': '#cad3f5',
    'grey0': '#6e738d', 'grey1': '#939ab7', 'grey2': '#a5adcb',
    'red': '#ed8796', 'orange': '#f5a97f', 'yellow': '#eed49f',
    'green': '#a6da95', 'aqua': '#91d7e3', 'blue': '#8aadf4', 'purple': '#c6a0f6',
  }
enddef

export def CatppuccinFrappe(): dict<string>
  return {
    'bg0': '#292c3c', 'bg1': '#303446', 'bg2': '#414559', 'bg3': '#51576d', 'bg5': '#626880',
    'fg0': '#c6d0f5',
    'grey0': '#737994', 'grey1': '#949cbb', 'grey2': '#a5adce',
    'red': '#e78284', 'orange': '#ef9f76', 'yellow': '#e5c890',
    'green': '#a6d189', 'aqua': '#99d1db', 'blue': '#8caaee', 'purple': '#ca9ee6',
  }
enddef

export def CatppuccinLatte(): dict<string>
  return {
    'bg0': '#e6e9ef', 'bg1': '#eff1f5', 'bg2': '#ccd0da', 'bg3': '#bcc0cc', 'bg5': '#acb0be',
    'fg0': '#4c4f69',
    'grey0': '#9ca0b0', 'grey1': '#7c7f93', 'grey2': '#6c6f85',
    'red': '#d20f39', 'orange': '#fe640b', 'yellow': '#df8e1d',
    'green': '#40a02b', 'aqua': '#04a5e5', 'blue': '#1e66f5', 'purple': '#8839ef',
  }
enddef

# Tokyo Night（ghifarit53/tokyonight.vim，取自其 s:palette）
export def TokyoNight(): dict<string>
  return {
    'bg0': '#1a1b26', 'bg1': '#232433', 'bg2': '#2a2b3d', 'bg3': '#32344a', 'bg5': '#3b3d57',
    'fg0': '#a9b1d6',
    'grey0': '#444B6A', 'grey1': '#444B6A', 'grey2': '#444B6A',
    'red': '#F7768E', 'orange': '#FF9E64', 'yellow': '#E0AF68',
    'green': '#9ECE6A', 'aqua': '#7AA2F7', 'blue': '#7AA2F7', 'purple': '#ad8ee6',
  }
enddef
