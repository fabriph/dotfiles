-- Neovim counterpart of ../vimrc.
--
-- The two files stay separate. Vim and Neovim disagree on bells, on how
-- options are set, and on how mappings are declared, so a shared file would
-- need guards in both directions.
--
-- Neovim is always UTF-8, so the 'encoding' and 'scriptencoding' lines from
-- the vimrc have no counterpart here.

-- BEHAVIOUR

-- Allows to press ';' instead of ':' for commands
vim.keymap.set({ "n", "x", "s", "o" }, ";", ":", { remap = false })
-- Allows to press 'ñ' for commands in spanish keyboards
vim.keymap.set({ "n", "x", "s", "o" }, "ñ", ":", { remap = false })

vim.o.cursorline = true
vim.o.number = true -- Line numbers.
vim.o.statusline = "%F %=%l:%c"
-- The vimrc sets 'vb' and then empties 't_vb'. Neovim dropped the termcap
-- options, so 'belloff' is how you silence both the sound and the flash.
vim.o.belloff = "all" -- No sounds, no visual bell.

-- VISUAL

vim.cmd("syntax on") -- Color syntax
vim.cmd.colorscheme("peachpuff")
vim.o.list = true -- Show invisible characters
vim.o.listchars = "tab:>·,trail:·" -- But only show tabs and trailing whitespace

vim.o.shortmess = "atI" -- Shorten messages and don't show intro
vim.o.showmatch = true -- Show matching brackets
vim.o.showcmd = true -- Show the command I'm writing

vim.o.laststatus = 2 -- Status bar.
