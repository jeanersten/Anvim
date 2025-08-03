vim.opt.completeopt = 'menuone,popup,noselect'
vim.opt.showfulltag = true

vim.opt.number = true
vim.opt.cursorline = true
vim.opt.cursorcolumn = true
vim.opt.cursorlineopt = 'line'
vim.opt.laststatus = 3
vim.opt.showtabline = 2
vim.opt.signcolumn = 'yes'
vim.opt.wrap = false
vim.opt.fillchars = { eob = " " }

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.smartcase = true
vim.opt.virtualedit = 'block'

vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.writebackup = false

vim.opt.confirm = true
vim.opt.mouse = 'a'
vim.opt.scrolloff = 8

vim.opt.statusline = '%!v:lua.setup_statusline()'
vim.opt.tabline = '%!v:lua.setup_tabline()'
vim.opt.showmode = false
