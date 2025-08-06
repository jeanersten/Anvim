local M = {}

local state = { -- store state variable
  floating = {
    prompt_buffer = -1,
    prompt_window = -1,
    list_buffer   = -1,
    list_window   = -1
  },
  separator           = vim.loop.os_uname().sysname == 'Windows_NT' and '\\' or '/',
  files               = {},
  filtered            = {},
  prompt              = '',
  list_selected       = 1,
  list_offset         = 0,
  previous_mode       = 'n',
  workspace_directory = vim.fn.getcwd(),
  title               = 'Picker'
}


-- Get Workspace Files
-- return : table of files in the workspace directory
local function get_workspace_files()
  local files = {} -- store table of files

  local function scan(path, relative_prefix)
    local handle = vim.loop.fs_scandir(path)
    if not handle then return end

    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then break end

      local full_path     = path .. state.separator .. name
      local relative_path = relative_prefix and (relative_prefix .. state.separator .. name) or name

      if type == 'file' then
        table.insert(files, relative_path)
      elseif type == 'directory' then
        scan(full_path, relative_path)
      end
    end
  end

  scan(state.workspace_directory, nil)
  table.sort(files)

  return files
end


-- Filter Files
local function filter_files()
  if state.prompt == '' then
    state.filtered = vim.deepcopy(state.files)
  else
    state.filtered = {}
    local pattern = state.prompt:lower()

    for _, file in ipairs(state.files) do -- loop through and find matchind pattern (in lowercase)
      if file:lower():find(pattern, 1, true) then
        table.insert(state.filtered, file)
      end
    end
  end

  state.list_selected = 1
  state.list_offset = 0
end


-- Render
local function render()
  if not (vim.api.nvim_buf_is_valid(state.floating.prompt_buffer))
  or not (vim.api.nvim_buf_is_valid(state.floating.list_buffer)) then
    return
  end

  local win_height = vim.api.nvim_win_get_height(state.floating.list_window)
  local prompt_line = '> ' .. state.prompt
  local lines = {}

  vim.api.nvim_buf_set_option(state.floating.prompt_buffer, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.floating.prompt_buffer, 0, -1, false, {prompt_line})

  if state.list_selected > state.list_offset + win_height then
    state.list_offset = state.list_selected - win_height
  elseif state.list_selected <= state.list_offset then
    state.list_offset = math.max(0, state.list_selected - 1)
  end

  for i = 1, win_height do -- fill the list with lines
    local id = i + state.list_offset
    if state.filtered[id] then
      if id == state.list_selected then
        table.insert(lines, '> ' .. state.filtered[id])
      else
        table.insert(lines, ' ' .. state.filtered[id])
      end
    else
      table.insert(lines, '')
    end
  end

  vim.api.nvim_buf_set_option(state.floating.list_buffer, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.floating.list_buffer, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.floating.list_buffer, 'modifiable', false)

  if vim.api.nvim_win_is_valid(state.floating.prompt_window) then
    local cursor_pos = 2 + #state.prompt
    vim.api.nvim_win_set_cursor(state.floating.prompt_window, {1, cursor_pos})
  end
end


-- Open Selected File
local function open_selected_file()
  if #state.filtered == 0 then return end

  local file = state.filtered[state.list_selected]
  if not file then return end

  vim.api.nvim_win_hide(state.floating.prompt_window)
  vim.api.nvim_win_hide(state.floating.list_window)
  state.floating.prompt_window = -1
  state.floating.list_window = -1

  vim.schedule(function()
    vim.cmd('edit ' .. vim.fn.fnameescape(file))
    if state.previous_mode == 'i' then
      vim.cmd('startinsert')
    else
      vim.cmd('stopinsert')
    end
  end)
end


-- Navigate Through Selection
-- param direction: 1 for down, -1 for up
local function navigate_selection(direction)
  local total = #state.filtered
  if total == 0 then return end

  if direction > 0 then
    state.list_selected = state.list_selected + 1
    if state.list_selected > total then
      state.list_selected = 1
    end
  else
    state.list_selected = state.list_selected - 1
    if state.list_selected < 1 then
      state.list_selected = total
    end
  end

  render()
end


-- Create Window
local function create_window(opts)
  opts = opts or {}
  local total_width  = math.floor(vim.o.columns * 0.5)                                   -- store window width
  local total_height = math.floor(vim.o.lines * 0.5)                                     -- store window height
  local start_row    = math.floor((vim.o.lines - math.floor(vim.o.lines * 0.5)) / 2)     -- store row location
  local start_col    = math.floor((vim.o.columns - math.floor(vim.o.columns * 0.5)) / 2) -- store colum location
  local prompt_buffer = nil
  local list_buffer   = nil

  local prompt_window_config = { -- neovim window config for prompt
    relative  = 'editor',
    width     = total_width,
    height    = 1,
    row       = start_row,
    col       = start_col,
    style     = 'minimal',
    border    = 'single',
    title     = (' ' .. state.title .. ' '),
    title_pos = 'center'
  }

  if vim.api.nvim_buf_is_valid(opts.prompt_buffer) then
    prompt_buffer = opts.prompt_buffer
  else
    prompt_buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(prompt_buffer, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(prompt_buffer, 'filetype', 'picker')
  end

  local prompt_window = vim.api.nvim_open_win(prompt_buffer, true, prompt_window_config)

  local list_window_config = { -- neovim window config for list
    relative = 'editor',
    width    = total_width,
    height   = total_height - 3,
    row      = start_row + 3,
    col      = start_col,
    style    = 'minimal',
    border   = 'single',
  }

  if vim.api.nvim_buf_is_valid(opts.list_buffer) then
    list_buffer = opts.list_buffer
  else
    list_buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(list_buffer, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(list_buffer, 'filetype', 'picker')
  end

  local list_window = vim.api.nvim_open_win(list_buffer, true, list_window_config)

  vim.api.nvim_set_hl(0, 'FloatBorder', {link = 'Normal'})
  vim.api.nvim_set_hl(0, 'NormalFloat', {link = 'Normal'})

  return {
    prompt_buffer = prompt_buffer,
    prompt_window = prompt_window,
    list_buffer = list_buffer,
    list_window = list_window
  }
end


-- Enable Keymaps
local function enable_keymaps()
  local prompt_opts = {buffer = state.floating.prompt_buffer, silent = true}

  -- esc or q to close
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_hide(state.floating.prompt_window)
    vim.api.nvim_win_hide(state.floating.list_window)
    state.floating.prompt_window = -1
    state.floating.list_window = -1
  end, prompt_opts)
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_hide(state.floating.prompt_window)
    vim.api.nvim_win_hide(state.floating.list_window)
    state.floating.prompt_window = -1
    state.floating.list_window = -1
  end, prompt_opts)

  -- enter open selected file
  vim.keymap.set({'n', 'i'}, '<CR>', open_selected_file, prompt_opts)

  -- tab to navigate down
  vim.keymap.set({'n', 'i'}, '<Tab>', function() navigate_selection(1) end, prompt_opts)

  -- shift+tab to navigate up
  vim.keymap.set({'n', 'i'}, '<S-Tab>', function() navigate_selection(-1) end, prompt_opts)

  -- enter insert mode and position cursor properly
  vim.keymap.set('n', 'i', function()
    local cursor_pos = 2 + #state.prompt
    vim.api.nvim_win_set_cursor(state.floating.prompt_window, {1, cursor_pos})
    vim.cmd('startinsert')
  end, prompt_opts)
  vim.keymap.set('n', 'a', function()
    local cursor_pos = 2 + #state.prompt
    vim.api.nvim_win_set_cursor(state.floating.prompt_window, {1, cursor_pos})
    vim.cmd('startinsert')
  end, prompt_opts)

  -- disable movement in normal mode
  for _, key in ipairs({'h', 'l', '0', '$', '^', '<Home>', '<End>'}) do
    vim.keymap.set('n', key, function()
      local cursor_pos = 2 + #state.prompt
      vim.api.nvim_win_set_cursor(state.floating.prompt_window, {1, cursor_pos})
    end, prompt_opts)
  end


  -- update prompt from input
  for i = 32, 126 do
    local char = string.char(i)
    vim.keymap.set('i', char, function()
      state.prompt = state.prompt .. char
      filter_files()
      render()
    end, prompt_opts)
  end
  vim.keymap.set('i', '<BS>', function()
    state.prompt = state.prompt:sub(1, -2)
    filter_files()
    render()
  end, prompt_opts)
  vim.keymap.set('i', '<C-u>', function()
    state.prompt = ''
    filter_files()
    render()
  end, prompt_opts)
end


-- Toggle
function M.toggle()
  if vim.api.nvim_win_is_valid(state.floating.prompt_window) or vim.api.nvim_win_is_valid(state.floating.list_window) then
    vim.api.nvim_win_hide(state.floating.prompt_window)
    vim.api.nvim_win_hide(state.floating.list_window)
    state.floating.prompt_window = -1
    state.floating.list_window = -1
  else
    state.floating = create_window({ prompt_buffer = state.floating.prompt_buffer, list_buffer = state.floating.list_buffer })
    state.previous_mode = vim.fn.mode()
    state.files = get_workspace_files()
    state.filtered = vim.deepcopy(state.files)
    state.prompt = ''
    state.list_selected = 1
    state.list_offset = 0

    enable_keymaps()
    render()

    vim.schedule(function()
      vim.api.nvim_set_current_win(state.floating.prompt_window)
      vim.api.nvim_win_set_cursor(state.floating.prompt_window, {1, 2})
    end)
  end
end


-- Setup
function M.setup()
  vim.api.nvim_create_user_command('ZPicker', M.toggle, {})
  vim.api.nvim_create_autocmd({'WinEnter', 'CmdlineEnter'}, {
    callback = function()
      if vim.api.nvim_win_is_valid(state.floating.prompt_window) or vim.api.nvim_win_is_valid(state.floating.list_window) then
        local current_win = vim.api.nvim_get_current_win()
        if current_win ~= state.floating.prompt_window and current_win ~= state.floating.list_window then
          vim.api.nvim_win_hide(state.floating.prompt_window)
          vim.api.nvim_win_hide(state.floating.list_window)
          state.floating.prompt_window = -1
          state.floating.list_window = -1
        end
      end
    end
  })

  vim.keymap.set('n', '<M-f>', M.toggle, {desc = 'Toggle Picker'})
end

return M
