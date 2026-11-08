return {
  file_types = { "markdown" },
  render_modes = { "n", "c" },
  anti_conceal = { enabled = false },
  -- Native mode handling switches only Markdown windows between raw and rendered.
  win_options = {
    conceallevel = { default = 0, rendered = 3 },
    concealcursor = { default = "", rendered = "nc" },
  },
  sign = { enabled = false },
  heading = { icons = { "" }, backgrounds = {} },
  code = {
    style = "language", language_icon = false, language_border = "",
    border = "none", highlight = "Normal", highlight_inline = "Normal",
  },
  bullet = { icons = { "•" } },
  checkbox = {
    unchecked = { icon = "☐ " }, checked = { icon = "☑ " },
    custom = { todo = { rendered = "◧ " } },
  },
  link = { enabled = false },
  latex = { enabled = false },
}
