-- Keep errors and commands native; diagnostics stay quiet until requested.
vim.diagnostic.config({
  signs = false,
  virtual_text = false,
  virtual_lines = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", header = "", prefix = "", max_width = 80, max_height = 14 },
})

local function plugin_colors()
  local p = require("colors").palette
  -- Default terminal background exposes Ghostty's image; zero blending masks code cells.
  vim.o.winblend = 0
  vim.o.pumblend = 0
  for name, fg in pairs({
    NormalFloat = p.foreground, FloatBorder = p.border,
    FloatTitle = p.type, FloatFooter = p.comment,
    Pmenu = p.foreground, PmenuSbar = p.border,
    DiagnosticFloatingError = p.error, DiagnosticFloatingWarn = p.warning,
    DiagnosticFloatingInfo = p.info, DiagnosticFloatingHint = p.hint,
    DiagnosticFloatingOk = p.type,
  }) do
    vim.api.nvim_set_hl(0, name, { fg = fg, bg = "NONE" })
  end
  -- Row backgrounds belong to the window/selection, never to individual labels.
  vim.api.nvim_set_hl(0, "InvisiblePopupText", { fg = p.foreground })
  vim.api.nvim_set_hl(0, "InvisiblePopupMuted", { fg = p.comment })
  vim.api.nvim_set_hl(0, "InvisiblePopupAccent", { fg = p.type, bold = true })
  vim.api.nvim_set_hl(0, "InvisiblePopupMarked", { fg = p.type, underline = true })
  vim.api.nvim_set_hl(0, "InvisiblePopupDeprecated", { fg = p.comment, strikethrough = true })
  vim.api.nvim_set_hl(0, "InvisiblePopupPreview", { fg = p.foreground, bg = p.search })

  local links = {
    MiniPickNormal = "NormalFloat", MiniPickBorder = "FloatBorder",
    MiniPickBorderBusy = "FloatBorder", MiniPickBorderText = "FloatTitle",
    MiniPickHeader = "InvisiblePopupAccent", MiniPickMatchCurrent = "PmenuSel",
    MiniPickMatchMarked = "InvisiblePopupMarked", MiniPickMatchRanges = "InvisiblePopupAccent",
    MiniPickPrompt = "FloatTitle", MiniPickPromptCaret = "FloatTitle", MiniPickPromptPrefix = "FloatTitle",
    MiniPickPreviewLine = "PmenuSel", MiniPickPreviewRegion = "InvisiblePopupPreview",
    MiniPickIconDirectory = "InvisiblePopupAccent", MiniPickIconFile = "InvisiblePopupText",

    MiniFilesNormal = "NormalFloat", MiniFilesBorder = "FloatBorder",
    MiniFilesBorderModified = "FloatTitle", MiniFilesCursorLine = "PmenuSel",
    MiniFilesDirectory = "InvisiblePopupAccent", MiniFilesFile = "InvisiblePopupText",
    MiniFilesTitle = "FloatTitle", MiniFilesTitleFocused = "FloatTitle",

    BlinkCmpMenu = "Pmenu", BlinkCmpMenuBorder = "FloatBorder", BlinkCmpMenuSelection = "PmenuSel",
    BlinkCmpScrollBarThumb = "PmenuThumb", BlinkCmpScrollBarGutter = "PmenuSbar",
    BlinkCmpLabel = "InvisiblePopupText", BlinkCmpLabelDetail = "InvisiblePopupMuted",
    BlinkCmpLabelDescription = "InvisiblePopupMuted", BlinkCmpLabelMatch = "InvisiblePopupAccent",
    BlinkCmpLabelDeprecated = "InvisiblePopupDeprecated", BlinkCmpSource = "InvisiblePopupMuted",
    BlinkCmpKind = "InvisiblePopupMuted", BlinkCmpGhostText = "InvisiblePopupMuted",
    BlinkCmpDoc = "NormalFloat", BlinkCmpDocBorder = "FloatBorder", BlinkCmpDocSeparator = "FloatBorder",
    BlinkCmpDocCursorLine = "PmenuSel", BlinkCmpSignatureHelp = "NormalFloat",
    BlinkCmpSignatureHelpBorder = "FloatBorder", BlinkCmpSignatureHelpActiveParameter = "InvisiblePopupMarked",
  }
  for name, target in pairs(links) do vim.api.nvim_set_hl(0, name, { link = target }) end
  vim.api.nvim_set_hl(0, "DiffAdd", { fg = p.type, bg = p.selection })
  vim.api.nvim_set_hl(0, "DiffDelete", { fg = p.error, bg = p.surface })
  vim.api.nvim_set_hl(0, "DiffChange", { bg = p.selection })
  vim.api.nvim_set_hl(0, "DiffText", { fg = p.foreground, bg = p.search })
end
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("InvisiblePluginColors", { clear = true }),
  callback = plugin_colors,
})
plugin_colors()
