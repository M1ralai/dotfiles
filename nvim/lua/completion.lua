require("blink.cmp").setup({
  keymap = {
    preset = "none",
    ["<CR>"] = { "select_and_accept", "fallback" },
    ["<C-n>"] = { "select_next", "show", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback" },
    ["<C-j>"] = { "select_next", "fallback" },
    ["<C-k>"] = { "select_prev", "fallback" },
    ["<C-y>"] = { "select_and_accept", "fallback" },
    ["<C-e>"] = { "cancel", "show", "fallback" },
    ["<C-g>d"] = { "show_documentation", "hide_documentation", "fallback" },
    ["<C-g>j"] = { "snippet_forward", "fallback" },
    ["<C-g>k"] = { "snippet_backward", "fallback" },
  },
  -- Pure Lua matching needs no native build, downloader or extra dependencies.
  fuzzy = { implementation = "lua" },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
  completion = {
    list = { selection = { preselect = false, auto_insert = false } },
    accept = { auto_brackets = { enabled = false } },
    menu = { border = "rounded", winblend = 0, draw = { columns = { { "label", "label_description", gap = 1 } } } },
    documentation = { auto_show = false, window = { border = "rounded", winblend = 0, max_width = 80, max_height = 16 } },
    ghost_text = { enabled = false },
  },
  signature = { enabled = false },
  cmdline = { enabled = false },
  term = { enabled = false },
})
