-- Get Mode String
-- return : string of the mode 
local function get_mode_string()
  local mode        = vim.fn.mode() -- get mode name
  local mode_string = {             -- table of string by mode name
    n       = 'NRML', -- NORMAL
    i       = 'INST', -- INSERT
    v       = 'VSAL', -- VISUAL
    V       = 'VLNE', -- VISUAL-LINE
    ['\22'] = 'VBLK', -- VISUAL-BLOCK
    s       = 'SLCT', -- SELECT
    S       = 'SLNE', -- SELECT-LINE
    ['\19'] = 'SBLK', -- SELECT-BLOCK
    c       = 'CMND', -- COMMAND
    R       = 'RPLC', -- REPLACE
    r       = 'RPLC', -- REPLACE (1 character)
    ['!']   = 'SHLL', -- SHELL
    t       = 'TRML'  -- TERMINAL
  }

  return mode_string[mode] or '????' -- return string by name or '????' as notation to unknown
end

-- Setup Statusline
-- return : string of neovim statusline formatting rule
function _G.setup_statusline()
  local file_name       = vim.fn.expand('%:t') -- get current active file name
  local mode_string     = get_mode_string()    -- get mode string
  local cursor_position = '%p%%:%l:%c'         -- get position info of the cursor in a file

  file_name = (file_name ~= '' and file_name) or 'No Name' -- file name will be 'No Name' if not recognized

  local format = { -- table of string formatting rule
    '%#StatusLine#', -- begin format
    ' ',             -- space
    mode_string,     -- mode string
    ' ',             -- space
    '|',             -- separator
    ' ',             -- space
    file_name,       -- file name
    ' ',             -- space
    '|',             -- separator   
    '%=',            -- equal space between
    '|',             -- separator
    ' ',             -- space
    cursor_position, -- cursor position
    ' ',             -- space
    '%#StatusLine#'  -- end format
  }

  return table.concat(format) -- return string of concatenated table 
end
