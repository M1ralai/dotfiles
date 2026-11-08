vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/saghen/blink.cmp", version = "v1.10.2" },
  { src = "https://github.com/nvim-mini/mini.nvim", version = "stable" },
  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
}, { confirm = false })

require("nvim-treesitter").setup({ install_dir = vim.fn.stdpath("data") .. "/site" })
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "" then return end
    local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
    if lang and pcall(vim.treesitter.start, ev.buf, lang) then
      vim.bo[ev.buf].syntax = ""
    end
  end,
})
-- Parser downloads are explicit (:TSInstall / :TSUpdate), never triggered by editing.
require("mini.ai").setup({ n_lines = 300 })
require("mini.surround").setup()
require("mini.pairs").setup()
require("mini.bufremove").setup()

local animate = require("mini.animate")
animate.setup({
  cursor = { enable = true },
  scroll = { timing = animate.gen_timing.linear({ duration = 120, unit = "total" }) },
  resize = { enable = false },
  open = { enable = false },
  close = { enable = false },
})

local git = require("gitsigns")
git.setup({
  signcolumn = false, signs_staged_enable = false, numhl = false,
  linehl = false, word_diff = false, current_line_blame = false,
  attach_to_untracked = false,
  preview_config = { border = "rounded", style = "minimal", relative = "cursor", row = 0, col = 1 },
  on_attach = function(buf)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
    end
    map("]h", function() git.nav_hunk("next") end, "Next Git hunk")
    map("[h", function() git.nav_hunk("prev") end, "Previous Git hunk")
    map("<leader>ghp", git.preview_hunk, "Preview hunk")
    map("<leader>ghs", git.stage_hunk, "Stage/unstage hunk")
    map("<leader>ghr", git.reset_hunk, "Reset hunk")
    map("<leader>ghd", git.diffthis, "Diff against index")
  end,
})

-- Register without loading; Markdown initializes the plugin on first use.
vim.pack.add({ { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" } }, { confirm = false, load = function() end })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  once = true,
  callback = function()
    vim.g.render_markdown_config = require("markdown")
    vim.cmd.packadd("render-markdown.nvim")
  end,
})
