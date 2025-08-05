local M = {}

local state = { -- store variable in the state
  floating = {
    buffer = -1,
    window = -1
  },
  title  = 'Terminal'
}


-- Create Window
local function create_window(opts)
  opts = opts or {}
  local width  = math.floor(vim.o.columns * 0.5)                                   -- store window width
  local height = math.floor(vim.o.lines * 0.5)                                     -- store window height
  local row    = math.floor((vim.o.lines - math.floor(vim.o.lines * 0.5)) / 2)     -- store row location
  local col    = math.floor((vim.o.columns - math.floor(vim.o.columns * 0.5)) / 2) -- store colum location
  local buffer = nil

  local window_config = { -- neovim window config
    relative  = 'editor',
    width     = width,
    height    = height,
    row       = row,
    col       = col,
    style     = 'minimal',
    border    = 'single',
    title     = (' ' .. state.title .. ' '),
    title_pos = 'center'
  }

  if vim.api.nvim_buf_is_valid(opts.buffer) then
    buffer = opts.buffer
  else
    buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buffer, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buffer, 'filetype', 'terminal')
  end

  local window = vim.api.nvim_open_win(buffer, true, window_config) -- open the window

  vim.api.nvim_set_hl(0, 'FloatBorder', {link = 'Normal'})
  vim.api.nvim_set_hl(0, 'NormalFloat', {link = 'Normal'})

  return {buffer = buffer, window = window}
end


-- Setup Keymaps
local function enable_keymaps()
  local opts = {buffer = state.floating.buffer, silent = true}

  -- esc or q to close
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_hide(state.floating.window)
  end, opts)
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_hide(state.floating.window)
  end, opts)
end


-- Toggle
function M.toggle()
  if vim.api.nvim_win_is_valid(state.floating.window) then
    vim.api.nvim_win_hide(state.floating.window)
    state.floating.window = -1
  else
    state.floating = create_window({ buffer = state.floating.buffer })
    if vim.bo[state.floating.buffer].buftype ~= 'terminal' then
      vim.cmd.term()
    end
    enable_keymaps()
  end
end


-- Setup
function M.setup()
  vim.api.nvim_create_user_command('ZTerminal', M.toggle, {})
  vim.api.nvim_create_autocmd({'WinEnter', 'CmdlineEnter'}, {
    callback = function()
      if vim.api.nvim_win_is_valid(state.floating.window) then
        vim.api.nvim_win_hide(state.floating.window)
        state.floating.window = -1
      end
    end,
  })

  vim.keymap.set('n', '<M-t>', M.toggle, {desc = 'Toggle Terminal'})
end

return M
