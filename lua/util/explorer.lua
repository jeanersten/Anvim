local M = {}

local state = { -- module window state
  floating = {
    buffer = -1,
    window = -1
  },
  current_directory   = vim.fn.getcwd(),
  workspace_directory = vim.fn.getcwd(),
  cursor_position     = 1
}

local icons = { -- module icons
  header_folder = '󱧶 ',
  up_folder     = '󰅃 ',
  folder        = '󰉋 ',
  file          = '󰈔 ',
  code          = '󰈮 ',
  config        = '󱁻 ',
  image         = '󰈟 ',
  text          = '󱇧 ',
  executable    = '󰲋 ',
}

-- Get File Icon
-- return : file icon from icon table
local function get_file_icon(name, is_directory)
  local extension = name:match('%.([^%.]+)$') -- capture everything after '.' in file name

  if is_directory then
    return icons.folder
  end
  
  if not extension then
    return icons.file
  end
  
  extension = extension:lower() -- convert extension to lower case
  
  if vim.tbl_contains({'lua', 'c', 'cpp', 'h', 'hpp'}, extension) then          -- code file
    return icons.code
  elseif vim.tbl_contains({'json', 'yaml', 'toml', 'conf'}, extension) then     -- config file
    return icons.config
  elseif vim.tbl_contains({'png', 'jpg', 'jpeg', 'gif', 'bmp'}, extension) then -- image file
    return icons.image
  elseif vim.tbl_contains({'txt', 'md'}, extension) then                        -- text file
    return icons.text
  elseif vim.tbl_contains({'exe'}, extension) then                              -- executable file
    return icons.executable
  else                                                                          -- fallback to default if not recognized
    return icons.file
  end
end

-- Get Directory Contents
-- return : table of every scanned contents
local function get_directory_contents(directory)
  local handle      = vim.loop.fs_scandir(directory) -- get directory handle
  local directories = {}                             -- store directories
  local files       = {}                             -- store files
  local items       = {}                             -- store all items
  local separator = vim.fn.has('win32') == 1 and '\\' or '/'                                                -- choose if platform using forwardslash or backslash
  local is_root   = (vim.fn.has('win32') == 1 and directory:match('^[A-Za-z]:[\\/]?$')) or directory == '/' -- get root directory
  
  if not handle then
    return items
  end

  if not is_root then
    table.insert(items, {
      name = '..',
      path = vim.fn.fnamemodify(directory, ':h'),
      is_directory = true,
      icon = icons.up_folder
    })
  end
  
  while true do -- scan recursively for items
    local name, type = vim.loop.fs_scandir_next(handle) -- handle directory
    local full_path  = ''                               -- full location path

    if not name then break end

    if directory:sub(-1) == separator then
      full_path = directory .. name
    else
      full_path = directory .. separator .. name
    end
    
    local is_directory = type == 'directory'       -- check if directory
    local icon = get_file_icon(name, is_directory) -- get file icon
    local item = { -- pack all information
      name = name,
      path = full_path,
      is_directory = is_directory,
      icon = icon
    }
    
    if is_directory then
      table.insert(directories, item)
    else
      table.insert(files, item)
    end
  end
  
  table.sort(directories, function(a, b) return a.name < b.name end)
  table.sort(files, function(a, b) return a.name < b.name end)
  
  for _, item in ipairs(directories) do -- insert created item in directories table to item container
    table.insert(items, item)
  end

  for _, item in ipairs(files) do       -- insert created item in files table to the item container
    table.insert(items, item)
  end
  return items
end

-- Display Buffer
-- return : table of every scanned contents
local function render_buffer(buffer, directory)
  local items = get_directory_contents(directory) -- store all items
  local lines = {}                                -- store line to display
  
  table.insert(lines, ' ' .. icons.header_folder .. ' ' .. directory)
  table.insert(lines, string.rep('─', 100))
  
  for _, item in ipairs(items) do -- loop through existing items and insert it to line
    local line = string.format('. %s %s', item.icon, item.name)
    if item.is_directory then
      line = line .. (vim.fn.has('win32') == 1 and '\\' or '/')
    end

    table.insert(lines, line)
  end
  
  vim.api.nvim_buf_set_option(buffer, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buffer, 'modifiable', false)
  
  return items
end

-- Create the Floating Window
-- return : table of buffer and window
local function create_floating_window(opts)
  opts = opts or {}
  local width  = math.floor(vim.o.columns * 0.20)             -- window width
  local height = math.floor(vim.o.lines * 0.85)               -- window height
  local row    = math.floor(((vim.o.lines - height) / 2) - 1) -- row location
  local col    = math.floor(1)                                -- colum location
  local buffer = nil
  
  local window_config = { -- neovim window config
    relative  = 'editor',
    width     = width,
    height    = height,
    row       = row,
    col       = col,
    style     = 'minimal',
    border    = 'single',
    title     = 'Explorer',
    title_pos = 'center',
  }

  if vim.api.nvim_buf_is_valid(opts.buffer) then
    buffer = opts.buffer
  else
    buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buffer, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buffer, 'filetype', 'file_explorer')
  end

  local window = vim.api.nvim_open_win(buffer, true, window_config) -- open the window

  vim.api.nvim_set_hl(0, 'FloatBorder', {link = 'Normal'})
  vim.api.nvim_set_hl(0, 'NormalFloat', {link = 'Normal'})
  
  return {buffer = buffer, window = window}
end

-- Handle Enter
-- return : nothing
local function handle_enter()
  local line_num   = vim.api.nvim_win_get_cursor(state.floating.window)[1] -- get line number index
  local line_space = 2                                                     -- first item from header
  local items      = get_directory_contents(state.current_directory )      -- get items from current directory
  local item_index = line_num - line_space                                 -- get item index in line
  
  if line_num <= line_space then
    return
  end
  
  if item_index > 0 and item_index <= #items then
    local item = items[item_index]

    if item.is_directory then
      state.current_directory = item.path
      render_buffer(state.floating.buffer, state.current_directory)
      vim.api.nvim_win_set_cursor(state.floating.window, {3, 0})
    else
      vim.api.nvim_win_hide(state.floating.window)
      vim.cmd('edit ' .. vim.fn.fnameescape(item.path))
    end
  end
end

-- Setup Keymaps
-- return : nothing
local function setup_keymaps(buffer)
  local opts = {buffer = buffer, silent = true}
  
  -- enter/2*mouse-left to open file/directory
  vim.keymap.set('n', '<CR>', handle_enter, opts)
  vim.keymap.set('n', '<2-LeftMouse>', handle_enter, opts)
  
  -- esc or q to close
  vim.keymap.set('n', '<Esc>', function()
    vim.api.nvim_win_hide(state.floating.window)
  end, opts)
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_hide(state.floating.window)
  end, opts)
  
  -- r to refresh with
  vim.keymap.set('n', 'r', function()
    render_buffer(state.floating.buffer, state.current_directory)
  end, opts)
  
  -- ~ to go home directory
  vim.keymap.set('n', '~', function()
    state.current_directory = vim.fn.expand('~')
    render_buffer(state.floating.buffer, state.current_directory)
    vim.api.nvim_win_set_cursor(state.floating.window, {3, 0})
  end, opts)
  
  -- / to go root directory
  vim.keymap.set('n', '/', function()
    local root_dir = vim.fn.has('win32') == 1 and 'C:\\' or '/'

    state.current_directory = root_dir
    render_buffer(state.floating.buffer, state.current_directory)
    vim.api.nvim_win_set_cursor(state.floating.window, {3, 0})
  end, opts)
  
  -- w to go back to workspace directory
  vim.keymap.set('n', 'w', function()
    state.current_directory = state.workspace_directory
    render_buffer(state.floating.buffer, state.current_directory)
    vim.api.nvim_win_set_cursor(state.floating.window, {3, 0})
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
    
    render_buffer(state.floating.buffer, state.current_directory)
    setup_keymaps(state.floating.buffer)
    
    vim.api.nvim_win_set_cursor(state.floating.window, {3, 0})
  end
end

-- Setup Module
-- return : nothing
function M.setup() vim.api.nvim_create_user_command('FileExplorer', M.toggle, {})
  vim.api.nvim_create_autocmd({'WinEnter', 'CmdlineEnter'}, {
    callback = function()
      if vim.api.nvim_win_is_valid(state.floating.window) then
        vim.api.nvim_win_hide(state.floating.window)
        state.floating.window = -1
      end
    end,
  })

  vim.keymap.set('n', '<M-e>', M.toggle, {})
end

return M
