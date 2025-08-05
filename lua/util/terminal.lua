local M = {}

local state = { -- module window state
  floating = {
    buffer = -1,
    window = -1
  },
  workspace_directory = vim.fn.getcwd()
}

-- Create the Floating Window
-- return : table of buffer and window
local function create_floating_window(opts)
  opts = opts or {}
  local width  = math.floor(vim.o.columns * 0.50)        -- window width
  local height = math.floor(vim.o.lines * 0.50)          -- window height
  local row    = math.floor((vim.o.lines - height) / 2)  -- row location
  local col    = math.floor((vim.o.columns - width) / 2) -- colum location
  local buffer = nil
  
  local window_config = { -- neovim window config
    relative  = 'editor',
    width     = width,
    height    = height,
    row       = row,
    col       = col,
    style     = 'minimal',
    border    = 'single',
    title     = 'Terminal',
    title_pos = 'center',
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

local function setup_keymaps(buffer)
  local opts = {buffer = buffer, silent = true}
  
  -- esc or q to close
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_hide(state.floating.window)
  end, opts)
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_hide(state.floating.window)
  end, opts)
end

-- Toggle Window
-- return : nothing
function M.toggle()
  if vim.api.nvim_win_is_valid(state.floating.window) then
    vim.api.nvim_win_hide(state.floating.window)
    state.floating.window = -1
  else
    state.floating = create_floating_window({ buffer = state.floating.buffer })

    if vim.bo[state.floating.buffer].buftype ~= 'terminal' then
      vim.cmd.term()
    end

    setup_keymaps(state.floating.buffer)
  end
end

-- Setup Module
-- return : nothing
function M.setup()
  vim.api.nvim_create_user_command('Terminal', M.toggle, {})
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
