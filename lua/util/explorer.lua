local M = {}

local state = { -- store variable in the state
  floating = {
    buffer = -1,
    window = -1
  },
  title  = 'Explorer' ,
  separator           = (vim.loop.os_uname().sysname == 'Windows_NT') and '\\' or '/',
  workspace_directory = vim.fn.getcwd(),
  current_directory   = vim.fn.getcwd(),
  cursor_position     = 1
}

local icons = { -- store icons to display
  header          = '󱧶 ',
  go_up           = '󰅃 ',
  folder_normal   = '󰉋 ',
  file_normal     = '󰈔 ',
  file_code       = '󰈮 ',
  file_config     = '󱁻 ',
  file_text       = '󱇧 ',
  file_image      = '󰈟 ',
  file_executable = '󰲋 '
}


-- Get File Icon
-- return : string of icon from *icons table
-- param file_name    : string of the file name to get
-- param is_directory : bool if the object is directory
local function get_content_icon(file_name, is_directory)
  local extension_code_list       = { -- store list of file with code type extension
    'c',
    'cpp',
    'h',
    'hpp',
  }
  local extension_config_list     = { -- store list of file with config type extension
    'conf',
    'json',
    'toml',
    'yaml',
  }
  local extension_text_list       = { -- store list of file with text type extension
    'md',
    'txt'
  }
  local extension_image_list      = { -- store list of file with image type extension
    'bmp',
    'gif',
    'jpg',
    'jpeg',
    'png'
  }
  local extension_executable_list = { -- store list of file with executable type extension
    'exe'
  }
  local extension = file_name:match('%.([^%.]+)$')

  if extension then
    extension = extension:lower() -- store file extension in lowercase
  end

  if is_directory then                                               -- directory
    return icons.folder_normal
  elseif not extension then                                          -- no extension
    return icons.file_normal
  elseif vim.tbl_contains(extension_code_list, extension) then       -- code file
    return icons.file_code
  elseif vim.tbl_contains(extension_config_list, extension) then     -- config file
    return icons.file_config
  elseif vim.tbl_contains(extension_text_list, extension) then       -- text file
    return icons.file_text
  elseif vim.tbl_contains(extension_image_list, extension) then      -- image file
    return icons.file_image
  elseif vim.tbl_contains(extension_executable_list, extension) then -- executable file
    return icons.file_executable
  else                                                               -- fallback to default if not recognized
    return icons.file_normal
  end
end


-- Get Directory Items
-- return : table of items in the current directory
local function get_directory_items()
  local is_root = (vim.loop.os_uname().sysname == 'Windows_NT') and state.current_directory:match('^[A-Za-z]:[\\/]?$') or state.current_directory == '/' -- store condition for root directory
  local handle = vim.loop.fs_scandir(state.current_directory) -- store data from directory
  local directories = {} -- store table of directories
  local files       = {} -- store table of files
  local items       = {} -- store table of all items found

  if not handle then
    return items
  elseif not is_root then
    table.insert(items, { -- add 'up 1 directory' if condition fulfilled
      name = '..',
      path = vim.fn.fnamemodify(state.current_directory, ':h'),
      icon = icons.go_up,
      is_directory = true
    })
  end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle) -- store name and type of item
    local full_path  = ''                               -- store full path of item

    if not name then
      break
    elseif state.current_directory:sub(-1) == state.separator then
      full_path = state.current_directory .. name
    else
      full_path = state.current_directory .. state.separator .. name
    end

    local is_directory = type == 'directory' -- store condition if item is directory
    local icon = get_content_icon(name, is_directory) -- store icon to use item
    local item = {                                    -- store all information into table
      name = name,
      path = full_path,
      icon = icon,
      is_directory = is_directory
    }

    if is_directory then
      table.insert(directories, item) -- add item to directories table
    else
      table.insert(files, item)       -- add item to files table
    end
  end

  table.sort(directories, function(a, b) return a.name:lower() < b.name:lower() end) -- sort directories by name
  table.sort(files, function(a, b) return a.name:lower() < b.name:lower() end)       -- sort files by name

  for _, directory in ipairs(directories) do -- loop through directories and add to items
    table.insert(items, directory)
  end
  for _, file in ipairs(files) do            -- loop through files and add to items
    table.insert(items, file)
  end

  return items
end


-- Render
local function render()
  local window_width = vim.api.nvim_win_get_width(state.floating.window) -- store window width
  local header = (' ' .. icons.header .. ' ' .. state.current_directory) -- store header to display
  local header_separator = string.rep('=', window_width) -- store header separator to display
  local items  = get_directory_items() -- store table of all items
  local lines  = {}                    -- store table of lines to display

  table.insert(lines, header)           -- header
  table.insert(lines, header_separator) -- header separator

  for _, item in ipairs(items) do -- loop through items
    local line = string.format('. %s %s', item.icon, item.name)

    if item.is_directory then
      line = line .. state.separator
    end

    table.insert(lines, line)
  end

  vim.api.nvim_buf_set_option(state.floating.buffer, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.floating.buffer, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.floating.buffer, 'modifiable', false)
end


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
    vim.api.nvim_buf_set_option(buffer, 'filetype', 'explorer')
  end

  local window = vim.api.nvim_open_win(buffer, true, window_config) -- open the window

  vim.api.nvim_set_hl(0, 'FloatBorder', {link = 'Normal'})
  vim.api.nvim_set_hl(0, 'NormalFloat', {link = 'Normal'})

  return {buffer = buffer, window = window}
end


-- Handle Enter
local function handle_enter()
  local line_num   = vim.api.nvim_win_get_cursor(state.floating.window)[1] -- store line number index
  local items      = get_directory_items()                                 -- store items from current directory
  local item_index = line_num - 2                                          -- store item index in line

  if line_num <= 2 then
    return
  end

  if item_index > 0 and item_index <= #items then
    local item = items[item_index]

    if item.is_directory then
      state.current_directory = item.path
      render()
      vim.api.nvim_win_set_cursor(state.floating.window, {3, 0})
    else
      vim.api.nvim_win_hide(state.floating.window)
      vim.cmd('edit ' .. vim.fn.fnameescape(item.path))
    end
  end
end


-- Setup Keymaps
local function enable_keymaps()
  local opts = {buffer = state.floating.buffer, silent = true}

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
    render()
  end, opts)

  -- ~ to go home directory
  vim.keymap.set('n', '~', function()
    state.current_directory = vim.fn.expand('~')
    render()
    vim.api.nvim_win_set_cursor(state.floating.window, {3, 0})
  end, opts)

  -- / to go root directory
  vim.keymap.set('n', '/', function()
    local root_dir = vim.fn.has('win32') == 1 and 'C:\\' or '/'

    state.current_directory = root_dir
    render()
    vim.api.nvim_win_set_cursor(state.floating.window, {3, 0})
  end, opts)

  -- w to go back to workspace directory
  vim.keymap.set('n', 'w', function()
    state.current_directory = state.workspace_directory
    render()
    vim.api.nvim_win_set_cursor(state.floating.window, {3, 0})
  end, opts)
end


-- Toggle
function M.toggle()
  if vim.api.nvim_win_is_valid(state.floating.window) then
    vim.api.nvim_win_hide(state.floating.window)
    state.floating.window = -1
  else
    state.floating = create_window({ buffer = state.floating.buffer })
    render()
    enable_keymaps()
    vim.api.nvim_win_set_cursor(state.floating.window, {3, 0})
  end
end


-- Setup
function M.setup()
  vim.api.nvim_create_user_command('ZExplorer', M.toggle, {})
  vim.api.nvim_create_autocmd({'WinEnter', 'CmdlineEnter'}, {
    callback = function()
      if vim.api.nvim_win_is_valid(state.floating.window) then
        vim.api.nvim_win_hide(state.floating.window)
        state.floating.window = -1
      end
    end,
  })

  vim.keymap.set('n', '<M-e>', M.toggle, {desc = 'Toggle Explorer'})
end

return M
