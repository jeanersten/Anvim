function _G.setup_tabline()
  local statusline_hl = vim.api.nvim_get_hl(0, { name = 'StatusLine' })
  
  vim.api.nvim_set_hl(0, 'TabLine', statusline_hl)
  vim.api.nvim_set_hl(0, 'TabLineFill', statusline_hl)
  vim.api.nvim_set_hl(0, 'TabLineSel', { fg = statusline_hl.fg, bg = statusline_hl.bg, bold = true })

  local banner   = 'Neovim!'
  local filename = vim.fn.expand('%:t')
  local tabs     = ''
  local flags = '%h%m%r'

  filename = (filename ~= '' and filename) or 'Untitled'

  for i = 1, vim.fn.tabpagenr('$') do
    local tab_hl = i == vim.fn.tabpagenr() and '%#TabLineSel#' or '%#TabLine#'
    tabs = tabs .. tab_hl .. i .. ' %T '
  end

  return '%#TabLine#' .. '  '.. banner .. ' |' .. '%=' .. filename .. flags .. '%=' .. '|  ' .. tabs .. ' ' .. '%#TabLine#'
end
