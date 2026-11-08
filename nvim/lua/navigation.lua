local pick = require("mini.pick")
local extra = require("mini.extra")
local files = require("mini.files")
-- Keep the explorer rooted where Neovim started, even after jumping to external sources.
local explorer_root = vim.fn.getcwd()
pick.setup({
  mappings = { refine = "", move_down = "<C-j>", move_up = "<C-k>" }, -- keep tmux's Ctrl-Space free; retain native picker paste/split keys
  source = { show = function(buf, items, query)
    pick.default_show(buf, items, query, { show_icons = false })
  end },
  window = { config = function()
    return {
      relative = "editor", anchor = "SW", row = vim.o.lines - vim.o.cmdheight,
      col = math.floor(vim.o.columns * 0.11), border = "rounded",
      width = math.floor(vim.o.columns * 0.78), height = math.min(16, math.floor(vim.o.lines * 0.38)),
    }
  end },
})
-- The existing picker also handles code actions and other explicit selections.
vim.ui.select = function(items, opts, on_choice)
  return pick.ui_select(items, opts, on_choice, { window = { config = function()
    return {
      relative = "editor", anchor = "SW", row = vim.o.lines - vim.o.cmdheight,
      col = math.floor(vim.o.columns * 0.11), border = "rounded",
      width = math.min(80, math.floor(vim.o.columns * 0.78)), height = math.max(1, math.min(8, #items)),
    }
  end } })
end
extra.setup()
files.setup({
  mappings = { go_in = "L", go_in_plus = "l" },
  content = { prefix = function() return "", "" end },
  options = { use_as_default_explorer = true, permanent_delete = false },
  windows = { max_number = 2, preview = false, width_focus = 45, width_nofocus = 25 },
})
local map = vim.keymap.set
map("n", "<leader>ff", pick.builtin.files, { desc = "Find files" })
map("n", "<leader><space>", pick.builtin.files, { desc = "Find files" })
map("n", "<leader>sg", pick.builtin.grep_live, { desc = "Search project text" })
map("n", "<leader>/", pick.builtin.grep_live, { desc = "Search project text" })
map("n", "<leader>fb", pick.builtin.buffers, { desc = "Select buffer" })
map("n", "<leader>fr", extra.pickers.oldfiles, { desc = "Recent files" })
map("n", "<leader>e", function()
  if not files.close() then
    files.open(explorer_root, false)
  end
end, { desc = "Toggle file explorer" })
map("n", "<leader>bd", function() require("mini.bufremove").delete(0, false) end, { desc = "Close buffer, keep window" })
map("n", "<leader>bb", "<C-^>", { desc = "Previous buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>ss", function() extra.pickers.lsp({ scope = "document_symbol" }) end, { desc = "Document symbols" })
map("n", "<leader>sS", function() extra.pickers.lsp({ scope = "workspace_symbol_live" }) end, { desc = "Workspace symbols" })
map("n", "<leader>xx", extra.pickers.diagnostic, { desc = "Workspace diagnostics" })

-- Reuse the installed Lazygit, only when explicitly requested.
map("n", "<leader>gg", function()
  if vim.fn.executable("lazygit") == 0 then return vim.notify("lazygit is not installed", vim.log.levels.WARN) end
  local buf = vim.api.nvim_create_buf(false, true)
  local width, height = math.floor(vim.o.columns * 0.9), math.floor(vim.o.lines * 0.85)
  local win = vim.api.nvim_open_win(buf, true, { relative = "editor", width = width, height = height,
    row = math.floor((vim.o.lines - height) / 2), col = math.floor((vim.o.columns - width) / 2),
    border = "rounded", style = "minimal" })
  vim.fn.jobstart({ "lazygit" }, { term = true, on_exit = function()
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
      if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
    end)
  end })
  vim.cmd.startinsert()
end, { desc = "Lazygit" })
