local capabilities = require("blink.cmp").get_lsp_capabilities()
local state = vim.fn.stdpath("state")
local configs = {
  gopls = { cmd = { "gopls" }, filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_markers = { "go.work", "go.mod", ".git" },
    settings = { gopls = { semanticTokens = false, completeUnimported = true } } },
  clangd = { cmd = { "clangd", "--header-insertion=never" }, filetypes = { "c", "cpp", "objc", "objcpp" },
    root_markers = { ".clangd", "compile_commands.json", "compile_flags.txt", ".git" } },
  rust_analyzer = { cmd = { "rust-analyzer" }, filetypes = { "rust" },
    root_markers = { "Cargo.toml", "rust-project.json", ".git" },
    settings = { ["rust-analyzer"] = { checkOnSave = false } } },
  lua_ls = { cmd = { "lua-language-server", "--logpath=" .. state .. "/lua-ls", "--metapath=" .. state .. "/lua-ls/meta" },
    filetypes = { "lua" }, root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
    settings = { Lua = { telemetry = { enable = false }, hint = { enable = false },
      workspace = { checkThirdParty = false } } },
    on_init = function(client)
      local folder = client.config.root_dir or ""
      -- Neovim globals belong only to this config, not to unrelated Lua projects.
      local config = vim.fn.stdpath("config")
      local name = vim.api.nvim_buf_get_name(0)
      if name:sub(1, #config + 1) == config .. "/" and not vim.uv.fs_stat(folder .. "/.luarc.json")
        and not vim.uv.fs_stat(folder .. "/.luarc.jsonc") then
        client.config.settings.Lua.runtime = { version = "LuaJIT" }
        client.config.settings.Lua.diagnostics = { globals = { "vim" } }
        client.config.settings.Lua.workspace.library = { vim.env.VIMRUNTIME }
        client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
      end
    end },
}
for name, config in pairs(configs) do
  config.capabilities = capabilities
  if vim.fn.executable(config.cmd[1]) == 1 then
    vim.lsp.config(name, config)
    vim.lsp.enable(name)
  end
end
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client then
      -- Use the established Treesitter palette instead of higher-priority token recoloring.
      client.server_capabilities.semanticTokensProvider = nil
    end
    vim.lsp.inlay_hint.enable(false, { bufnr = ev.buf })
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
    end
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gr", function() require("mini.extra").pickers.lsp({ scope = "references" }) end, "References")
    map("gI", vim.lsp.buf.implementation, "Implementation")
    map("gy", vim.lsp.buf.type_definition, "Type definition")
    map("K", function() vim.lsp.buf.hover({ border = "rounded", max_width = 80, max_height = 16 }) end, "Hover documentation")
    map("gK", function() vim.lsp.buf.signature_help({ border = "rounded", max_width = 80, max_height = 8 }) end, "Signature help")
    map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
  end,
})
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = false }) end, { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = false }) end, { desc = "Previous diagnostic" })
