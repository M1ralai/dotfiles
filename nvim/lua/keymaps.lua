vim.g.mapleader = " "
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr><Esc>", { desc = "Clear search highlighting" })
vim.keymap.set("n", "<leader>n", "<cmd>set nonumber relativenumber!<cr>", { desc = "Toggle line numbers" })
-- Native window navigation stays on Ctrl-W; Ctrl-Space belongs to tmux.

-- Familiar editing shortcuts from the existing configuration.
local map = vim.keymap.set
map("i", "jj", "<Esc>", { desc = "Exit insert mode", silent = true })
map("i", "kk", "<Esc>", { desc = "Exit insert mode", silent = true })
-- Suppress :move messages: with cmdheight=0 they can collapse the restored selection.
map("v", "J", ":silent m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
map("v", "K", ":silent m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })
map("n", "n", "'Nn'[v:searchforward].'<Cmd>lua MiniAnimate.execute_after(\"scroll\", \"normal! zvzz\")<CR>'", { expr = true, desc = "Next search result" })
map("n", "N", "'nN'[v:searchforward].'<Cmd>lua MiniAnimate.execute_after(\"scroll\", \"normal! zvzz\")<CR>'", { expr = true, desc = "Previous search result" })
map("n", "<C-d>", '<C-d><Cmd>lua MiniAnimate.execute_after("scroll", "normal! zz")<CR>', { desc = "Half page down" })
map("n", "<C-u>", '<C-u><Cmd>lua MiniAnimate.execute_after("scroll", "normal! zz")<CR>', { desc = "Half page up" })
map("n", "<leader>sh", "<cmd>vertical resize -10<cr>", { desc = "Narrow split" })
map("n", "<leader>sl", "<cmd>vertical resize +10<cr>", { desc = "Widen split" })
map("n", "<leader>sj", "<cmd>resize +10<cr>", { desc = "Increase split height" })
map("n", "<leader>sk", "<cmd>resize -10<cr>", { desc = "Decrease split height" })
map("x", "<leader>ac", function() require("ai").ask("codex") end, { desc = "Ask Codex about selection" })
map("x", "<leader>ag", function() require("ai").ask("agy") end, { desc = "Ask Antigravity about selection" })
map("x", "<leader>ae", function() require("ai").propose_edit() end, { desc = "Request Codex edit proposal" })
