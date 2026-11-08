local M = {}

-- Edit the palette here, then run :colorscheme invisible to reapply it.
M.palette = {
  foreground = "#DFE3DA", keyword = "#DBA785", type = "#AAC6B4",
  string = "#C8BC85", func = "#B0C3D5", comment = "#778F8C",
  gutter = "#626F70", border = "#465453", surface = "#192128",
  selection = "#344341", search = "#465149", muted = "#A6B2AE",
  error = "#C88686", warning = "#C8BC85", info = "#B0C3D5", hint = "#AAC6B4",
}

function M.apply()
  vim.cmd("highlight clear")
  vim.g.colors_name = "invisible"
  local p = M.palette
  local function hl(name, spec) vim.api.nvim_set_hl(0, name, spec) end
  local function link(name, target) hl(name, { link = target }) end

  for _, name in ipairs({ "Normal", "NormalNC", "SignColumn", "EndOfBuffer" }) do
    hl(name, { fg = p.foreground, bg = "NONE", ctermbg = "NONE" })
  end
  for _, name in ipairs({ "LineNr", "LineNrAbove", "LineNrBelow", "CursorLineNr" }) do
    hl(name, { fg = p.gutter, bg = "NONE", ctermbg = "NONE" })
  end
  for _, name in ipairs({ "CursorLine", "CursorColumn", "ColorColumn", "FoldColumn", "Folded", "WinSeparator" }) do
    hl(name, { fg = p.gutter, bg = "NONE" })
  end
  hl("Comment", { fg = p.comment, italic = true })
  hl("Statement", { fg = p.keyword })
  hl("Type", { fg = p.type })
  hl("String", { fg = p.string })
  hl("Function", { fg = p.func })
  hl("Identifier", { fg = p.foreground })
  link("goFunctionCall", "Function")
  link("Title", "Type")
  link("Directory", "Function")
  hl("Constant", { fg = p.string })
  hl("Special", { fg = p.keyword })
  hl("PreProc", { fg = p.keyword })
  hl("Delimiter", { fg = p.muted })
  hl("Operator", { fg = p.muted })
  for _, name in ipairs({ "Keyword", "Conditional", "Repeat", "Exception", "Label" }) do link(name, "Statement") end
  for _, name in ipairs({ "Structure", "StorageClass", "Typedef" }) do link(name, "Type") end
  for _, name in ipairs({ "Number", "Float", "Boolean", "Character" }) do link(name, "Constant") end
  for _, name in ipairs({ "Include", "Define", "Macro", "PreCondit" }) do link(name, "PreProc") end
  hl("Todo", { fg = p.type, bold = true, bg = "NONE" })
  hl("Error", { fg = p.error, bg = "NONE" })
  hl("ErrorMsg", { fg = p.error, bg = "NONE" })
  hl("WarningMsg", { fg = p.warning, bg = "NONE" })
  hl("MoreMsg", { fg = p.type })
  hl("Question", { fg = p.func })
  hl("ModeMsg", { fg = p.muted })
  hl("NonText", { fg = p.gutter, bg = "NONE" })
  hl("SpecialKey", { fg = p.gutter, bg = "NONE" })
  hl("Visual", { bg = p.selection })
  hl("Search", { fg = p.foreground, bg = p.search })
  hl("IncSearch", { fg = p.surface, bg = p.type })
  link("CurSearch", "IncSearch")
  hl("MatchParen", { fg = p.type, underline = true, bg = "NONE" })
  hl("Cursor", { fg = p.surface, bg = p.foreground })
  link("lCursor", "Cursor")
  hl("NormalFloat", { fg = p.foreground, bg = p.surface })
  hl("FloatBorder", { fg = p.border, bg = p.surface })
  hl("FloatTitle", { fg = p.type, bg = p.surface })
  hl("FloatFooter", { fg = p.comment, bg = p.surface })
  hl("Pmenu", { fg = p.foreground, bg = p.surface })
  hl("PmenuSel", { fg = p.foreground, bg = p.selection })
  hl("PmenuSbar", { bg = p.surface })
  hl("PmenuThumb", { bg = p.border })
  link("PmenuBorder", "FloatBorder")
  link("PmenuMatch", "Function")
  hl("PmenuMatchSel", { fg = p.func, bg = p.selection })
  for _, name in ipairs({ "PmenuKind", "PmenuExtra" }) do link(name, "Pmenu") end
  for _, name in ipairs({ "PmenuKindSel", "PmenuExtraSel" }) do link(name, "PmenuSel") end
  for _, name in ipairs({ "LspSignatureActiveParameter", "LspReferenceText", "LspReferenceRead", "LspReferenceWrite" }) do
    hl(name, { underline = true, sp = p.border, bg = "NONE" })
  end
  for _, severity in ipairs({ "Error", "Warn", "Info", "Hint", "Ok" }) do
    local color = ({ Error = p.error, Warn = p.warning, Info = p.info, Hint = p.hint, Ok = p.type })[severity]
    hl("Diagnostic" .. severity, { fg = color })
    hl("DiagnosticUnderline" .. severity, { undercurl = true, sp = color, bg = "NONE" })
    hl("DiagnosticFloating" .. severity, { fg = color, bg = p.surface })
    link("DiagnosticSign" .. severity, "Diagnostic" .. severity)
    link("DiagnosticVirtualText" .. severity, "Diagnostic" .. severity)
  end
  for _, name in ipairs({ "SpellBad", "SpellCap", "SpellLocal", "SpellRare" }) do
    hl(name, { undercurl = true, sp = p.comment, bg = "NONE" })
  end

  -- Native syntax works now; these captures prepare the same palette for 3B.
  local captures = {
    ["@comment"] = "Comment", ["@keyword"] = "Keyword", ["@type"] = "Type",
    ["@string"] = "String", ["@character"] = "Character", ["@number"] = "Number",
    ["@boolean"] = "Boolean", ["@function"] = "Function", ["@function.method"] = "Function",
    ["@constructor"] = "Type", ["@variable"] = "Identifier", ["@variable.member"] = "Identifier",
    ["@constant"] = "Constant", ["@module"] = "Type", ["@property"] = "Identifier",
    ["@operator"] = "Operator", ["@punctuation"] = "Delimiter", ["@attribute"] = "PreProc",
    ["@markup.heading"] = "Type", ["@markup.link"] = "Function", ["@markup.raw"] = "String",
  }
  for name, target in pairs(captures) do link(name, target) end
  -- Semantic tokens must reuse the syntax palette rather than add new colors.
  local semantic = { namespace = "@module", type = "@type", class = "@type",
    enum = "@type", interface = "@type", struct = "@type", typeParameter = "@type",
    parameter = "@variable", variable = "@variable", property = "@property",
    enumMember = "@constant", event = "@function", ["function"] = "@function",
    method = "@function.method", macro = "PreProc", keyword = "@keyword",
    modifier = "@keyword", comment = "@comment", string = "@string", number = "@number",
    regexp = "@string", operator = "@operator", decorator = "@attribute" }
  for name, target in pairs(semantic) do link("@lsp.type." .. name, target) end
  hl("@lsp.mod.deprecated", { strikethrough = true })
end
return M
