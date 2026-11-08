local o = vim.opt

-- Ghostty xterm-256color and tmux RGB output were verified in Phases 1/2.
o.termguicolors = true
o.background = "dark"
o.laststatus = 0
o.showtabline = 0
o.winbar = ""
o.showmode = false
o.showcmd = false
o.ruler = false
o.cmdheight = 0
o.shortmess:append("I")
o.number = false
o.relativenumber = true
o.numberwidth = 3
o.signcolumn = "no"
o.foldcolumn = "0"
o.cursorline = false
o.cursorcolumn = false
o.colorcolumn = ""
o.list = false
o.fillchars:append({ eob = " ", vert = " ", horiz = " ", horizup = " ",
  horizdown = " ", vertleft = " ", vertright = " ", verthoriz = " " })
o.belloff = "all"
o.visualbell = false
o.errorbells = false
o.guicursor = "a:block-blinkon0,n-v-c:block,i-ci:ver25,r-cr:hor20"
-- Native wrapped-line scrolling; mini.animate handles the scroll animation.
o.smoothscroll = true
o.scrolloff = 3
o.winborder = "rounded"
o.pumborder = "rounded"
o.winblend = 0
o.pumblend = 0

-- Use the richer syntax already shipped with Neovim; no parser downloads.
vim.g.go_highlight_functions = 1
vim.g.go_highlight_function_calls = 1
vim.g.go_highlight_types = 1

-- Reuse existing tools, without changing the shell or the LazyVim installation.
local mason = vim.fn.expand("~/.local/share/nvim/mason/bin")
if vim.fn.isdirectory(mason) == 1 then vim.env.PATH = vim.env.PATH .. ":" .. mason end
o.undofile = true
o.clipboard = "unnamedplus"
o.ignorecase = true
o.smartcase = true
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = -1
o.updatetime = 250
-- Filetype plugins and project EditorConfig remain authoritative.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "c", "cpp", "rust" },
  callback = function(ev)
    vim.bo[ev.buf].shiftwidth = vim.bo[ev.buf].filetype == "go" and 0 or 4
    vim.bo[ev.buf].tabstop = vim.bo[ev.buf].filetype == "go" and 8 or 4
    vim.bo[ev.buf].expandtab = vim.bo[ev.buf].filetype ~= "go"
  end,
})
