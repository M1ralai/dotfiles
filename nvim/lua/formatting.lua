local conform = require("conform")
conform.setup({
  formatters_by_ft = {
    go = { "gofmt" }, c = { "clang_format" }, cpp = { "clang_format" },
    rust = { "rustfmt" }, lua = { "stylua" },
  },
  formatters = {
    clang_format = {
      prepend_args = function(_, ctx)
        -- Respect project styles; otherwise match this editor's C/C++ indentation.
        local style = vim.fs.find({ ".clang-format", "_clang-format" }, { path = ctx.dirname, upward = true })[1]
        if style then return {} end
        return { "--style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never}" }
      end,
    },
  },
  format_on_save = function(buf)
    -- Off by default; opt in per buffer with Space u f.
    if vim.b[buf].invisible_format_on_save then return { timeout_ms = 1500, lsp_format = "never" } end
  end,
})
vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  conform.format({ async = true, lsp_format = "never" })
end, { desc = "Format buffer or selection" })
vim.keymap.set("n", "<leader>uf", function()
  vim.b.invisible_format_on_save = not vim.b.invisible_format_on_save
  vim.notify("Format on save: " .. (vim.b.invisible_format_on_save and "on (this buffer)" or "off"))
end, { desc = "Toggle format on save for this buffer" })
