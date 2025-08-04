-- Get File Name
-- return : string of file name
local function get_file_name()
  local file_name = ''
  
  if vim.bo.filetype == 'file_explorer' then
    file_name = 'Explorer'
  elseif vim.bo.buftype == 'terminal' then
    file_name = 'Terminal'
  else
    file_name = vim.fn.expand('%:t')
    file_name = (file_name ~= '' and file_name) or 'No Name'
  end

  return file_name
end

-- Setup Tabline
-- return : string of neovim tabline formatting rule
function _G.setup_tabline()
  local statusline_hl = vim.api.nvim_get_hl(0, {name = 'StatusLine'}) -- get statusline highlight
  local banner     = 'Neovim!'       -- banner/title to show
  local file_name  = get_file_name() -- get file name
  local file_flags = '%h%m%r'        -- get file flags
  local tabs       = ''              -- contain tabs

  file_name = (file_name ~= '' and file_name) or 'No Name' -- file name will be 'No Name' if not recognized

  for i = 1, vim.fn.tabpagenr('$') do -- loop through tab list, then mark active one
    local tab_hl = i == vim.fn.tabpagenr() and '%#TabLineSel#' or '%#TabLine#'
    tabs = tabs .. tab_hl .. i .. ' %T'
  end

  vim.api.nvim_set_hl(0, 'TabLine', statusline_hl)                                                  -- set tabline (inactive) style same as the statusline
  vim.api.nvim_set_hl(0, 'TabLineFill', statusline_hl)                                              -- settabline background same as the statusline
  vim.api.nvim_set_hl(0, 'TabLineSel', {fg = statusline_hl.fg, bg = statusline_hl.bg, bold = true}) -- set active tabline to use bold style

  local format = { -- table of string formatting rule
    '%#TabLine#', -- begin format
    ' ',          -- space
    banner,       -- banner/title
    ' ',          -- space
    '|',          -- separator
    '%=',         -- equal space between
    file_name,    -- file name
    ' ',          -- space
    file_flags,   -- file flags
    '%=',         -- equal space between
    '|',          -- separator
    ' ',          -- space
    tabs,         -- tabs
    ' ',          -- space
    '%#TabLine#'  -- end format
  }

  return table.concat(format) -- return string of concatenated table 
end
