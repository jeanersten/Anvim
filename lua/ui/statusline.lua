local function mode_icon()
  local mode = vim.fn.mode()
  local modes = {
    n       = 'NML',
    i       = 'INS',
    v       = 'VSL',
    V       = 'VLN',
    ['\22'] = 'VBK',
    c       = 'CMD',
    s       = 'SLT',
    S       = 'SLN',
    ['\19'] = 'SBK',
    R       = 'RPC',
    r       = 'RPC',
    ['!']   = 'SHL',
    t       = 'TRM'
  }

  return modes[mode] or '???' .. mode:upper()
end

function _G.setup_statusline()
  local filename = vim.fn.expand('%:t')
  local pos = '%p%%:%l:%c'

  filename = (filename ~= '' and filename) or 'No Name'

  return '%#StatusLineBold#' .. '   ' .. mode_icon() .. '   |' .. ' ' .. filename .. ' |' .. '%=' .. '| ' .. pos .. ' ' .. '%#StatusLine#'
end
