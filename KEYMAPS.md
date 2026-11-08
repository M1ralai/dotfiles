# Invisible Workspace — Neovim, tmux & AI Developer Handbook

> A hands-on guide for programming with **Neovim + tmux + Codex**, from the very first Vim keystroke to reviewing AI-generated code changes. You do not need to know the editor beforehand. Everything lives in one document; no permanent AI panel or dashboard.
>
> **Based on the supplied configuration:** `nvim/init.lua`, `nvim/lua/*.lua`, `tmux/tmux.conf`, `tmux/agent-popup`, `ghostty/config`, `README.md` and the previous `KEYMAPS.md` supplied with this archive. Native Vim commands below are standard editor functionality; custom commands are identified separately. Shell aliases and the wallpaper app's actual runtime configuration were **not** included in this archive, so their full keymaps cannot be certified here.

## 0. Read this first: notation and a quick start

| Notation | Meaning |
|---|---|
| `Space` / `<leader>` | Press Space in **Normal** or specified Visual mode; this config sets leader to Space |
| `Ctrl-x` / `<C-x>` | Hold Control and press x |
| `Ctrl-Space A` | Press Ctrl-Space (tmux prefix), **release**, then uppercase `A` (Shift+A) |
| `Esc` | Leave Insert/Visual mode or cancel a menu; in Normal mode it clears search highlighting |
| `Enter`, `<CR>` | Return/Enter key |
| `:` | In Normal mode, open Neovim's command line; type command and Enter |
| `v`, `V`, `Ctrl-v` | Characterwise, linewise, and blockwise Visual selections |
| `n`, `i`, `x`, `v`, `t` | Keymap mode designations: Normal, Insert, Visual, Visual+Select, Terminal |
| `foo → bar` | Before/after behavior; **not** keys to type |

**Important:** Vim shortcuts are sequential. `Space a e` means Space, then a, then e; not all at once. tmux shortcuts are a separate prefix sequence. `Space a c/g/e` only work **while selected text is in Visual mode**, not as global Normal mappings.

**Your first minute:**

```sh
# On the original machine:
NVIM_APPNAME=nvim-invisible nvim .
# On a fresh machine, after copying this repo's nvim/ to ~/.config/nvim:
nvim .
```

1. `Space Space` opens a file picker. Type part of a filename and press Enter.
2. `j`/`k` move down/up, `h`/`l` left/right; `i` enters Insert mode; `Esc` returns to Normal.
3. `:w` saves; `:q` quits; `:wq` saves and quits. `:q!` discards unsaved changes to the current buffer.
4. `Space e` opens the temporary file explorer; press `q` inside it to close.
5. `v` starts a selection. Select text, then `Space a c` to ask Codex or `Space a e` to propose a change (if the CLI is available).

## 1. Vim modes: how the editor thinks

| Mode | Enter | Exit | Used for |
|---|---|---|---|
| **Normal** | `Esc` from editing; default startup mode | `i`, `a`, `v`, `:`, etc. | Movement, edits, commands |
| **Insert** | `i`, `a`, `o`, `O`, `I`, `A` | `Esc`, or custom `jj` / `kk` | Typing text |
| **Visual (characterwise)** | `v` | `Esc` | Select characters / substrings |
| **Visual Line** | `V` | `Esc` | Select whole lines |
| **Visual Block** | `Ctrl-v` | `Esc` | Rectangular selection; AI edits do not support this |
| **Command-line** | `:` (or `/` and `?` for search) | Enter / Esc | Ex commands, search, substitution |
| **Replace** | `R` | `Esc` | Overwrite text as you type |
| **Terminal** | `:terminal` (native) | `Ctrl-\\ Ctrl-n` to Terminal-Normal | Interact with a program inside an editor terminal |

### Insert & line-edit commands (native except `jj`, `kk`)

| Keys | Effect |
|---|---|
| `i` / `a` | Insert before / after cursor |
| `I` / `A` | Insert at first nonblank character / at end of line |
| `o` / `O` | Open line below / above and insert |
| `s` / `S` | Delete character / line contents and insert |
| `rX` / `R` | Replace one character with X / continuous Replace mode |
| `Esc`, `jj`, `kk` | Leave Insert mode; `jj` and `kk` are **custom** |
| `Ctrl-o` (Insert) | Execute one Normal command and return to Insert |
| `Ctrl-r` followed by register (Insert) | Insert text from a register (e.g., `Ctrl-r "`) |
| `Ctrl-w` (Insert) | Delete preceding word |
| `Ctrl-u` (Insert) | Delete text back to start of current insertion/line context |

## 2. Navigation — standard Vim, then Invisible changes

### Basic movement and counts

| Keys | Meaning |
|---|---|
| `h j k l` | Left, down, up, right |
| `5j`, `3w` | Repeat motion 5 or 3 times; numbers prefix many commands |
| `w` / `W` | Next word / next whitespace-separated WORD |
| `b` / `B` | Previous word / WORD |
| `e` / `E` | End of current/next word / WORD |
| `ge` / `gE` | End of previous word / WORD |
| `0` / `^` / `$` | Line start / first nonblank / line end |
| `g_` | Last nonblank character on line |
| `gg` / `G` | File start / end; `42G` goes to line 42 |
| `42gg` / `:42` | Go to line 42 |
| `H` / `M` / `L` | Top / middle / bottom **visible screen** line (native, preserved) |
| `%` | Matching bracket/parenthesis, where supported |
| `fX` / `FX` | Find next / previous `X` on the current line |
| `tX` / `TX` | Stop just before next / previous `X` |
| `;` / `,` | Repeat / reverse last `f`, `F`, `t`, or `T` search |
| `}` / `{` | Next / previous paragraph-like boundary |
| `Ctrl-o` / `Ctrl-i` | Go backward / forward through jump list |
| `gi` | Return to last Insert position and enter Insert mode |
| `zz` / `zt` / `zb` | Center / top / bottom current line on screen |
| `Ctrl-d` / `Ctrl-u` | Half-page down / up **and center afterwards** (custom wrapping of native motion) |
| `n` / `N` | Next / previous search match in the search direction, with custom view-centering animation |

**Example: finding a character and reaching the value:** on `player = 12`, `f=` moves to `=` and `l` moves after it; `t=` stops **before** `=`. To move past the `=` efficiently use `f=l` or `f=w` as appropriate.

### Marks and jumps (native)

| Keys | Purpose |
|---|---|
| `ma` | Set mark `a` at cursor |
| `` `a `` / `'a` | Jump to exact marked position / marked line |
| `` `` `` / `''` | Jump back to previous position / line |
| `:marks` / `:jumps` | Inspect marks / jump history |
| `Ctrl-]` / `Ctrl-t` | Tag jump / go back (if tags available) |

## 3. Operators, text objects and precise edits

Vim combines an **operator** + an optional **count** + a **motion or text object**. Example: `d` (delete) + `iw` (inner word) → `diw`.

| Keys | Effect | Example |
|---|---|---|
| `x` / `X` | Delete char under cursor / preceding char | `abc` → `ac` with x on b |
| `dd` / `3dd` | Delete 1 / 3 lines | Entire line(s) removed |
| `D` / `d$` | Delete to end of line | Retains text before cursor |
| `dw` | Delete through next word boundary | Best when movement matches intention |
| `diw` / `daw` | Delete inner word / word including surroundings | `hello world` → `hello ` if cursor on `world` with `diw` |
| `ciw` / `caw` | Replace inner / around word, entering Insert | `count` → `total` with `ciwtotal<Esc>` |
| `cc` / `C` | Change whole line / remainder of line | Enter Insert afterwards |
| `yy` / `3yy` | Yank (copy) one / 3 lines | Does not change buffer |
| `yw` / `yiw` | Yank movement / inner word | Copy selection into unnamed register |
| `p` / `P` | Paste after / before cursor (or line) | Register contents |
| `J` | Join next line to current | Native Normal-mode behavior |
| `~` | Toggle case at cursor | `a` ↔ `A` |
| `guw` / `gUw` | Lowercase / uppercase word | Native |
| `.` | Repeat last change | Useful after `ciw` / `x` |
| `u` / `Ctrl-r` (Normal) | Undo / redo | Also applies to accepted AI edits |
| `>>` / `<<` | Indent / unindent one line | `3>>` for three lines |
| `=` + motion, `gg=G` | Reindent range / all lines | Uses editor indent rules, **not** same as `Space cf` formatter |

### Text objects: `i` means *inside*, `a` means *around*

| Object | Meaning | Typical use |
|---|---|---|
| `iw` / `aw` | Inner word / whole word with adjacent whitespace | `ciw`, `daw` |
| `iW` / `aW` | Whitespace-delimited WORD | `diW` |
| `i(` / `a(` or `i)` / `a)` | Within parentheses / including them | `ci(`, `da)` |
| `i[` / `a[` | Bracket interior / including brackets | `ci[` |
| `i{` / `a{` | Brace interior / including braces | `di{` |
| `i"` / `a"`, `i'` / `a'`, `` i` `` / `` a` `` | Quoted strings | `ci"` |
| `ip` / `ap` | Paragraph interior / including whitespace context | `dip` |
| `it` / `at` | HTML/XML tag contents / whole tag (where applicable) | `cit` |

`mini.ai` is configured (`n_lines = 300`) to extend text object recognition. The entries above are standard familiar objects; plugin-specific extra object behavior should be checked against the installed mini.ai version and `:h MiniAi` rather than inventing custom mappings.

### Visual operations

| Keys | Effect |
|---|---|
| `v`, `V`, `Ctrl-v` | Start character / line / rectangular selection |
| `o` (in Visual) | Jump cursor to the other end of selection |
| `d`, `y`, `c` | Delete / copy / change selected text |
| `>`, `<` | Indent / unindent selection |
| `=` | Reindent selection |
| `gv` | Reselect last Visual area |
| `J` / `K` (Visual) | **Custom:** move selected lines down / up, then reindent and reselect |
| `I` / `A` (Visual Block) | Insert at beginning / append at end of block; finish with Esc |

## 4. Surround: mini.surround — complete practical usage

`mini.surround` is explicitly configured with `require('mini.surround').setup()`, so its **default** `sa`, `sd`, `sr`, `sf`, `sF`, `sh`, `sn` mappings apply (unless overridden elsewhere). It is not the vim-surround plugin; do **not** assume its `ys` mapping exists.

| Keys | Purpose | Example |
|---|---|---|
| `sa` + text object / motion + char | Add surrounding pair | `saiw)` wraps inner word in `( )` |
| `sd` + surrounding char | Delete surrounding pair | `sd)` removes nearest matching `( )` |
| `sr` + old char + new char | Replace surrounding pair | `sr)'` turns `(hello)` into `'hello'` |
| `sf` + char | Find surrounding pair to the right | Navigate across surroundings |
| `sF` + char | Find surrounding pair to the left | Navigate across surroundings |
| `sh` + char | Highlight surrounding pair | Inspect what would be affected |
| `sn` | Change number of neighboring lines searched | Mini.surround prompt; consult `:h MiniSurround` |

**Before → command → after:**

```text
hello                 -- cursor on hello, type saiw)
(hello)

(hello)               -- cursor inside parentheses, type sd)
hello

(hello)               -- cursor inside parentheses, type sr)'
'hello'

hello world           -- Visual-select hello, then sa)
(hello) world
```

**Paired character choice:** using a closing bracket such as `)` normally yields spacing-tight `(text)`; opening-bracket variants can use spaced pair style depending on mini.surround input conventions. For exact behavior run `:h MiniSurround`. For quotes use `'`, `"`, or backtick. Don't confuse `sa` with the different `mini.ai` operator objects (`a`/`i`).

## 5. Searching, replacing, registers, macros

### Search (native; rendering of matches is customized)

| Keys | Meaning |
|---|---|
| `/pattern` + Enter | Search forward |
| `?pattern` + Enter | Search backward |
| `n` / `N` | Next / opposite-direction result (centered by custom mapping) |
| `*` / `#` | Search word under cursor forward / backward |
| `:nohlsearch` / `Esc` in Normal | Clear highlights (Esc has custom mapping) |
| `:set ignorecase` / `:set noignorecase` | Case-insensitive / case-sensitive search |
| `\c` / `\C` within pattern | Force case-insensitive / case-sensitive for that pattern |

This configuration sets `ignorecase=true`, `smartcase=true`: lowercase searches ignore case, uppercase letters normally trigger case-sensitive matching.

### Substitution (native)

```vim
:s/old/new/g                " current line, all occurrences
:%s/old/new/g               " entire file
:10,20s/old/new/g           " lines 10 through 20
:'<,'>s/old/new/g           " selection range (Visual then :)
:%s/old/new/gc              " confirm each match
:%s/old/new/gi              " ignore case for this replacement
:%s/old/new/gI              " force case-sensitive
```

In substitution, `&` means reuse the previous replacement flags in some contexts, and `\v` enables very-magic regex. Use `:h :substitute` for escaping `/`, capture groups and advanced expressions. Relative line numbers only affect display; `:10,20s` still uses absolute buffer line numbers. A range relative to cursor can use `:.,.+5s/old/new/g`.

### Registers and clipboard (native)

| Keys | Behavior |
|---|---|
| `"ayy` | Copy current line to named register `a` |
| `"ap` | Paste contents of `a` |
| `"_dd` | Delete without overwriting unnamed register (black-hole) |
| `"0p` | Paste last yank (as distinct from a later deletion) |
| `"+y` / `"+p` | Copy / paste system clipboard register |
| `:registers` | Inspect registers |
| `Ctrl-r a` (Insert) | Insert register `a` text at cursor |

`clipboard=unnamedplus` is enabled, so normal yank/paste integrates with system clipboard on supported platforms. A remote/headless environment may need a working clipboard provider.

### Macros (native)

```text
qa        start recording into register a
...       perform edits and motions
q         stop recording
@a        replay macro a
@@        repeat most recent macro
10@a      replay ten times
```

To avoid recursive surprises, try the macro on a copy or use `u` to undo. `q` in Normal editor mode starts macro recording, but **inside AI response viewers** it is locally remapped to **Hide**; inside mini.files it closes the explorer.

## 6. Buffers, windows, tabs and project navigation

**Buffer =** open file/text in memory. **Window =** viewport showing a buffer. **Tab page =** layout of windows (not the same as a browser tab). Opening a split doesn't duplicate the file contents. Unsaved changes remain in the buffer.

### Native navigation & window management

| Keys / commands | Action |
|---|---|
| `:e path` / `:edit path` | Open a file |
| `:w` / `:wa` | Save current / all modified buffers |
| `:q` / `:qa` | Quit window / all windows (fails if protected unsaved work) |
| `:wq` / `:x` | Save and exit |
| `:q!` | Quit without saving current window's changes |
| `:ls` / `:buffers` | List buffers |
| `:b N` / `:b filename` | Switch to numbered / named buffer |
| `:bnext` / `:bprevious` | Next / previous buffer |
| `Ctrl-^` | Alternate buffer |
| `:split` / `:vsplit` | Horizontal / vertical split |
| `Ctrl-w h/j/k/l` | Move focus to left/down/up/right window |
| `Ctrl-w w` / `Ctrl-w p` | Cycle / previous window |
| `Ctrl-w q` / `:close` | Close current window |
| `Ctrl-w =` / `Ctrl-w _` / `Ctrl-w |` | Equalize / maximize height / maximize width |
| `:tabnew` / `:tabnext` / `:tabprevious` | Create / navigate native tab pages |
| `:pwd` / `:cd path` / `:lcd path` | Show directory / change global / window-local working directory |
| `:terminal` | Open a native terminal buffer (not the tmux agent popup) |

### Invisible Workspace custom navigation map

| Keys | Mode | Action / notes |
|---|---|---|
| `Space Space`, `Space ff` | Normal | mini.pick file search |
| `Space /`, `Space sg` | Normal | Live project grep (`mini.pick`) |
| `Space fb` | Normal | Open-buffer picker |
| `Space fr` | Normal | Recent files (`mini.extra`) |
| `Space e` | Normal | Toggle `mini.files` explorer anchored at editor startup working directory |
| `Space bb` / `Ctrl-^` | Normal | Switch to alternate buffer |
| `[b` / `]b` | Normal | Previous / next buffer |
| `Space bd` | Normal | Close buffer using mini.bufremove; keep window, protect unsaved content |
| `Space ss` / `Space sS` | Normal | Document symbols / live workspace symbols (LSP) |
| `Space sh` / `Space sl` | Normal | Make split 10 columns narrower / wider |
| `Space sj` / `Space sk` | Normal | Make split 10 rows taller / shorter |
| `Space n` | Normal | Toggle relative numbers while keeping absolute number column disabled |

### mini.pick interactive keys

| Keys | Action |
|---|---|
| Type text | Fuzzy-filter candidates or live grep text |
| Enter | Choose current candidate |
| Esc | Dismiss picker |
| `Ctrl-n` / `Ctrl-p` | Move down / up |
| `Ctrl-j` / `Ctrl-k` | Explicit configured move down / up |
| `Tab` | Preview selection |
| `Ctrl-s` / `Ctrl-v` | Open selected item in horizontal / vertical split |

mini.pick layout: centered toward bottom, rounded border; icons disabled. It is used for certain `vim.ui.select` menus too.

### mini.files explorer keys

| Keys | Action |
|---|---|
| `Space e` (Normal outside explorer) | Toggle explorer |
| `h` / `l` | Go out to parent / enter directory or open item |
| `L` | Open item and close explorer (`go_in` override) |
| `q` | Close mini.files |
| `g?` | Show mini.files key help |
| `=` | Synchronize staged filesystem edits; inspect prompts before confirming |

Deletion uses `mini.files` non-permanent-delete behavior (`permanent_delete=false`); treat filesystem edits as real actions and verify the destination. Other mini.files shortcuts are plugin defaults and can be inspected with `g?` within the explorer.

## 7. Code intelligence: LSP, diagnostics, completion, formatting

### Language servers and source-dependent keys

An LSP keymap becomes active **when a compatible language server attaches**. If a tool is missing, mappings such as `gd`, `K`, `Space cr` are not guaranteed in that buffer.

| Keys | Mode | Action |
|---|---|---|
| `gd` | Normal with LSP | Go to definition |
| `gr` | Normal with LSP | References via mini.extra picker |
| `gI` | Normal with LSP | Go to implementation |
| `gy` | Normal with LSP | Go to type definition |
| `K` | Normal with LSP | Hover docs (temporary float) |
| `gK` | Normal with LSP | Signature help (temporary float) |
| `Space cr` | Normal with LSP | Rename symbol across applicable files; review changes |
| `Space ca` | Normal with LSP | Code action list |
| `Space cd` | Normal | Show diagnostics under cursor as float |
| `Space xx` | Normal | Workspace diagnostics picker |
| `[d` / `]d` | Normal | Previous / next diagnostic |

| Language | LSP executable | Formatter | Config root cues |
|---|---|---|---|
| Go | `gopls` | `gofmt` | `go.work`, `go.mod`, `.git` |
| C/C++ | `clangd` | `clang-format` | `.clangd`, `compile_commands.json`, `compile_flags.txt`, `.git` |
| Rust | `rust-analyzer` | `rustfmt` | `Cargo.toml`, `rust-project.json`, `.git` |
| Lua | `lua-language-server` | `stylua` | `.luarc.json[c]`, `.git` |

`gopls` has `completeUnimported=true`. Inlay hints, CodeLens, native LSP semantic recoloring and noisy virtual diagnostics are disabled; diagnostics remain underlined, retrievable on demand. The old Mason bin directory, if present, is appended to Neovim's PATH; nothing is installed by this config.

### blink.cmp: actual mappings from `lua/completion.lua`

| Keys | Condition | Effect |
|---|---|---|
| Enter | Completion menu offers a candidate | **Select and accept** proposal; otherwise fallback to normal Enter |
| `Ctrl-n` / `Ctrl-j` | Insert & completion | Next completion item, or show menu (for Ctrl-n) |
| `Ctrl-p` / `Ctrl-k` | Insert & completion | Previous completion item |
| `Ctrl-y` | Insert & completion | Accept selected candidate |
| `Ctrl-e` | Insert & completion | Cancel menu; or reopen depending on state |
| `Ctrl-g` then `d` | Insert & completion | Toggle documentation popup |
| `Ctrl-g` then `j` / `k` | Insert & active snippet | Next / previous placeholder |

Sources: LSP, buffer text, paths, snippets. No ghost text or auto docs. Automatic brackets **from blink completion** are disabled, but **mini.pairs is enabled** (see below), so automatic brackets from that separate plugin may still appear. `Tab` is not repurposed by blink here.

### Formatting and indentation

| Keys | Mode | Meaning |
|---|---|---|
| `Space cf` | Normal / Visual | Async format current buffer or selection via conform |
| `Space uf` | Normal | Toggle format-on-save **for current buffer**, initially off |
| `gg=G` | Normal | Native reindent the entire buffer; not external formatter |
| `>` / `<` | Visual | Shift selection's indentation |
| `>>` / `<<` | Normal | Shift current line |

General editing default is two spaces, C/C++/Rust are four spaces, Go uses tabs and tabstop eight. Project `.clang-format` takes priority; without one, clang-format falls back to LLVM with four-space indentation. Existing project EditorConfig/filetype rules can override base options. An unsaved AI Accept is **not** auto-formatted or saved.

## 8. Git & Lazygit

Git hunk keymaps are **buffer-local** on tracked files when gitsigns attaches; no permanent sign-column, blame or diff marks appear.

| Keys | Action |
|---|---|
| `[h` / `]h` | Previous / next Git hunk |
| `Space ghp` | Preview current hunk |
| `Space ghs` | Stage / unstage current hunk |
| `Space ghr` | Reset current hunk (**destructive to that hunk's working-tree changes**) |
| `Space ghd` | Diff buffer against Git index |
| `Space gg` | Lazygit in temporary terminal float; requires `lazygit` installed |

Lazygit is an independent terminal program; follow its own UI controls. Closing its process closes the float. The same letter `q` inside different UI buffers may have different meanings.

## 9. Markdown & visual presentation

| Action | Keys / command |
|---|---|
| Markdown render on normal/command view | Automatic, after first Markdown file loads `render-markdown.nvim` |
| Raw Markdown in Insert mode | Automatic; your actual file text remains unchanged |
| Toggle buffer rendering | `:RenderMarkdown buf_toggle` |
| Open/close side-by-side Markdown preview | `:RenderMarkdown preview` (provided by plugin when loaded) |
| Reload Invisible color palette | `:colorscheme invisible` |

Theme: no permanent statusline, tabline, winbar, dashboard, code-sign gutter, inlay hints or ghost text. Transparent highlights and temporary rounded floats preserve the wallpaper-based aesthetic. `mini.animate` handles cursor and scroll animation; native `smoothscroll` is on. `mini.pairs` creates matching pairs automatically under its plugin defaults, independent of blink's disabled auto-bracket feature.

## 10. tmux — the outer workspace

**tmux prefix is Ctrl-Space**, not the tmux default Ctrl-b. Press the prefix, release it, then the command. This works when Neovim is focused because tmux intercepts prefix keys. Tmux may need a new server or `tmux source-file ~/.tmux.conf` after configuration changes.

### Confirmed configured tmux bindings

| Keys | Scope | Effect |
|---|---|---|
| `Ctrl-Space` then `h/j/k/l` | Outer tmux | Focus left/down/up/right pane |
| `Ctrl-Space` then `S` | Outer tmux | Toggle visible tmux status bar |
| `Ctrl-Space` then `P` | Outer tmux | Open shell popup in current pane directory (80% wide, 70% high) |
| `Ctrl-Space` then `A` | Workspace | Show/create persistent Codex agent popup |
| `Ctrl-Space` then `G` | Workspace | Show/create persistent Antigravity popup if CLI verified |
| `Ctrl-Space` then `Ctrl-Space` | Outer tmux | Send literal Ctrl-Space prefix onward |

Additional **native tmux prefix defaults** remain unless overridden/unbound. Common ones: `c` creates window, `n`/`p` next/previous window, `w` window chooser, `s` session chooser, `d` detach, `%` vertical side-by-side pane split, `"` top-bottom pane split, `z` zoom/unzoom active pane, `x` close pane with confirmation, `?` list key bindings. Check actual active table with `tmux list-keys -T prefix`; defaults vary by tmux version, and the config specifically unbinds `Ctrl-b` as prefix.

### Open, hide, resume, and close an AI agent

| Keys | Context | Effect |
|---|---|---|
| `Ctrl-Space A` | Outside Codex popup | Create/show Codex in current origin tmux session & project directory |
| `Ctrl-Space G` | Outside Antigravity popup | Create/show Antigravity if available |
| `Ctrl-Space A` | Inside Codex popup | **Hide** its nested client; process stays alive |
| `Ctrl-Space G` | Inside Antigravity popup | **Hide** its nested client; process stays alive |
| `Ctrl-Space H` | Inside either agent popup | **Hide** without terminating session |
| `Ctrl-Space X` then `y` | Inside either agent popup | **Close** this integration-owned session/process after confirmation |
| `Ctrl-Space X` then `n` or Esc | Popup | Cancel Close |
| `Ctrl-Space Ctrl-Space` | Popup | Send literal Ctrl-Space to agent |

**Show → Hide → Show** resumes the *same running interactive process*. **Close → Show** starts fresh. Hiding returns to editor even if an agent is still working. Tmux popup is centered at ~85% width/height. Other agent's toggle is not usable through the current popup; hide first, then show the other. Escape and Ctrl-c go to the agent itself, not the popup lifecycle.

**Project identity:** helper uses `pane_current_path` and origin tmux session ID to name agent sessions, not the currently open source filename. If you change Neovim's `:cd` it may change the inferred project directory. Different origin sessions or directories get distinct sessions. A hidden process may continue after Neovim exits; closing the tmux server ends it. This is **not** persistence across machine reboot.

**CLI support:** interactive Codex uses a read-only sandbox and no-approval mode in the supplied launcher. Antigravity is optional: `agy` must be installed and pass the helper’s checks. Installing the CLI alone does **not** enable Visual Q&A; that workflow requires separately verified read-only execution.

## 11. AI-powered development: questions, changes, and code review

The tmux interactive agent and Neovim's **one-off, non-interactive** Visual requests are **separate**. Questions and edit proposals do **not** inherit the conversation history of the persistent tmux Codex instance.


### Choose the right AI workflow

| You want to… | Do this | Does it remember earlier requests? | Can it change your file? |
|---|---|---|---|
| Discuss a project over several turns | `Ctrl-Space A` to open Codex's tmux popup | **Yes**, while the interactive process remains running | The launcher uses read-only sandbox; this is separate from Neovim's approval feature |
| Ask what a function does | Select it, then `Space a c` | **No**: each Visual question is a separate CLI request | **No**, read-only Q&A |
| Request a safe code rewrite | Select it, then `Space a e` | **No**: each proposal is a separate CLI request | **Only if you explicitly press `a` in the diff viewer** |
| Compare an AI suggestion without deciding | Use `q` in diff, later `:AIProposalShow` | The proposal stays in Neovim memory | **No** until accepted |

The **interactive agent popup** is a terminal session: you type directly into Codex, hide it, edit code, and reopen it later. The **Visual AI tools** are Neovim windows and short-lived CLI requests. They do not send messages into the interactive popup's conversation. If you ask twice using `Space a c`, Codex does not automatically remember the first answer. If you run `Space a e` twice, the second request sees the *new selection*, not the history of your previous proposal.

### Guided workflow: understand an unfamiliar codebase

1. Start in the project root, for example `cd my-project && NVIM_APPNAME=nvim-invisible nvim .` inside tmux.
2. Open files with `Space Space`; enter a filename fragment and press Enter. For a symbol, use `gd` to jump to its definition and `Ctrl-o` to jump back.
3. Move to a function, select its lines with `V` and repeated `j` (or a count such as `5j`), then `Space a c`.
4. Ask: *Explain the ownership of this buffer, identify possible errors, and point to the relevant lines.* Press Enter.
5. Scroll the response normally (`j/k`, `Ctrl-d/u`). Press `q` to hide it and keep editing. `:AIShow` restores the same answer.
6. For a longer discussion, open the persistent Codex popup with `Ctrl-Space A`. Use `Ctrl-Space H` to hide it and the same `Ctrl-Space A` to reopen.

**Remember:** `V` selects whole lines. `v` selects characters. `Ctrl-v` selects a rectangle; that is fine for some normal Vim operations but **not supported** for AI edit proposals.

### Guided workflow: make a reviewed code change

Imagine this Go code in a project:

```go
counter++
fmt.Println(counter)
```

1. Put the cursor on `counter++`, press `Vj` to select two lines.
2. Press `Space a e`; enter *Make this code concurrency-safe and preserve the output semantics*. Press Enter.
3. Read the **unified diff**. Lines beginning with `-` come from the selection; lines beginning with `+` are proposed replacements. Review context and confirm that required locks or variables exist in the surrounding code. A suggestion can be syntactically valid and still be wrong for your program.
4. Press `q` if you want to inspect other code first. The proposal stays available via `:AIProposalShow`.
5. Press `a` **inside the diff** to apply the exact replacement to the original in-memory buffer. Or press `r`/`Q` to reject without changing anything.
6. After Accept, inspect the source, use `u` if you want to undo, and `:w` only when you decide to save. If you change the source while the proposal is pending, Accept refuses the stale edit. Select the updated lines and request a new proposal.

**There are two separate approvals:** Codex generates a proposal in a read-only process; Neovim alone applies it after your `a` key. `a` in a normal source buffer has Vim's usual meaning; the approval shortcut is local to the temporary diff viewer.

### Guided workflow: edit while an agent keeps thinking

1. Inside tmux press `Ctrl-Space`, release it, then `Shift+A` to open Codex.
2. Ask a question in its terminal UI, then press `Ctrl-Space H` to **hide** the popup without ending the process.
3. Continue working in Neovim. You can even use `Space a c` on a selection while the other interactive Codex process exists; their conversations remain separate.
4. Press `Ctrl-Space A` to reattach to the original interactive agent. The conversation is retained as long as that agent process is alive.
5. To terminate it, press `Ctrl-Space X`, then `y` **inside the popup**. Show it again to start a fresh process.

**Hide vs Close:** hiding is not a cancellation command. Background activity and usage may continue. Closing ends only the integration-owned tmux agent session; this is distinct from closing an AI response viewer with `Q`.

### If something goes wrong during a review

- **`stale` or conflict:** source was edited, renamed, unloaded, or deleted since the selection. A new proposal is needed; no automatic relocation is attempted.
- **AI didn't return code:** invalid/empty response is rejected. Nothing is applied; retry with a narrower selection and clearer request.
- **Viewer disappeared:** reopen with `:AIShow` for questions or `:AIProposalShow` for a pending diff. `q` hides; `Q` generally discards in these viewers.
- **Request times out:** the non-interactive process has a two-minute timeout; the persistent tmux agent is unaffected.
- **Need to revert an accepted replacement:** in the source buffer press `u` before subsequent edits, or use regular Git tools to inspect changes. Accept does not save to disk.

### All Neovim AI mappings and commands

| Keys / command | Context | Result |
|---|---|---|
| `Space a c` | **Visual selection** | Ask Codex about selected text |
| `Space a g` | **Visual selection** | Try Antigravity Q&A (currently deliberately disabled unless enforceably read-only) |
| `Space a e` | **Visual selection** | Ask **Codex** for an edit proposal; no immediate source changes |
| `:AISelectionInfo` | After Visual selection or live Visual | Show captured selection range, bytes and preview; does not call AI |
| Enter | AI question/edit input float | Submit request |
| Esc | AI question/edit input float | Cancel request without running AI |
| `q` | AI answer/review viewer | **Hide** float; retain answer/proposal |
| `Q` | AI answer viewer | **Close** answer; cancel running Q&A |
| `a` | AI diff viewer | **Accept** replacement after validation |
| `r` / `Q` | AI diff viewer | **Reject** and discard proposal |
| `:AIShow` | Ex command | Reopen last answer/pending request viewer |
| `:AIClose` | Ex command | Close active AI UI; cancel its request; saved proposal may remain |
| `:AIProposalShow` | Ex command | Reopen last retained edit diff/proposal |
| `:AIProposalDiscard` | Ex command | Discard saved proposal; cancel pending edit |

### Example A — ask about a selection

```go
counter++
fmt.Println(counter)
```

1. In Normal mode move onto `counter++`, press `Vj` (linewise two-line selection); or use `v` and motion keys.
2. Press `Space a c`, type *Is this concurrency-safe?*, Enter.
3. Codex runs asynchronously with a read-only sandbox and returns text in a Markdown float.
4. Press `q` to hide; keep editing. Run `:AIShow` to reopen; `Q` or `:AIClose` discards it.

### Example B — propose then approve an edit

1. Select the actual code with `v` or `V` (not Ctrl-v block selection).
2. `Space a e`, type *Make this code concurrency-safe*, Enter.
3. Codex generates **replacement code only**; Neovim shows a unified diff. **No source edit has happened.**
4. `q` hides the diff; `:AIProposalShow` brings it back.
5. `a` accepts only if the original buffer is still loaded, modifiable, matches original captured text/path/byte coordinates and has unchanged `changedtick`. The result remains **unsaved** until `:w`. Press `u` in source buffer to undo.
6. `r` or `Q` rejects, leaving source untouched. If the source changed while waiting, Accept blocks and marks it **stale**; create a new proposal.

**AI limitations:** blockwise edits unsupported; suggestions are not compiled or automatically executed. Unsaved buffer text is sent via stdin as part of prompt; source disk file may differ. Q&A has 120-second timeout; cancellation/timeout targets only the request process group. Existing Codex configurations with unreviewed project/system tool access may cause Q&A to refuse execution. Codex responses are untrusted. Accept modifies only the captured selection, with a single undoable buffer API operation; it neither saves nor formats. Disk-only changes are not detected by current stale-buffer check.

## 12. Ghostty, shell and working-directory behavior

`ghostty/config` in the provided archive contains Rose Pine Dawn (light) / Rose Pine (dark), font size 19, hidden titlebar, 10px padding, background blur and an image. This archive defines **no custom Ghostty keybind lines**, so ordinary Ghostty shortcuts are not claimed as Invisible-specific mappings. Consult Ghostty's installed keybinding list for system/version-specific shortcuts.

**Portability warning:** the supplied `ghostty/config` currently contains `/Users/REPLACE_ME/...` paths for `background-image` and generated wallpaper configuration. These are **placeholders**, not functional paths: substitute the real paths during installation; do not assume they are expanded automatically. The wallpaper generated config and image are not provided in these sources.

Shell aliases/functions and wallpaper scripts were not included in this keymaps-source archive. Do not assume `f`, `ff`, `gacp`, `mkcd` etc. exist from this file alone; check the live `zsh/` repo directory or shell configuration before documenting their actual implementation. tmux uses terminal/pane working directory; Neovim explorer is deliberately rooted at the editor launch directory, while project searches and AI project-root discovery may follow different rules.

## 13. Plugins, installation and maintenance

| Plugin | What it provides | Load behavior |
|---|---|---|
| nvim-treesitter | Syntax parsing & highlight | Base startup |
| blink.cmp | Autocompletion, snippets | Base startup |
| mini.nvim | pick, extra, files, ai, surround, **pairs**, animate, bufremove | Base startup |
| conform.nvim | Optional manual/opt-in save formatting | Base startup |
| gitsigns.nvim | Hunk navigation and actions | Base startup |
| render-markdown.nvim | Rendering of Markdown | Registered at startup; loaded on first Markdown FileType |

Plugins are managed with native `vim.pack` and `nvim-pack-lock.json` in the active repo. From Neovim:

```vim
:lua vim.pack.update()
:TSInstall bash c cpp go json lua markdown markdown_inline rust toml yaml
:TSUpdate
:colorscheme invisible
:checkhealth
:verbose map <Space>ae
```

`:verbose map` / `:verbose nmap` / `:verbose xmap` are useful to identify which file owns a binding, particularly where plugins may override defaults. `:map` lists all configured mappings. Use `:h index`, `:h motion.txt`, `:h MiniSurround`, `:h MiniFiles`, `:h MiniPick`, `:h vim.lsp` for primary in-editor help.

This configuration uses Neovim 0.12 APIs including `vim.pack` and native LSP setup. CLI dependencies such as `rg`, `gopls`, `clangd`, `rust-analyzer`, `lua-language-server`, and formatters must be installed separately. `lazygit`, `codex`, `agy` are optional, each for its named feature.

## 14. Troubleshooting recipes

| Symptom | What to check |
|---|---|
| `Space a e` does nothing | Are you **still in Visual mode**, in a normal editable file buffer? Try `V` then `Space a e`. |
| AI Q&A disabled | `:messages`, `codex --help`, CLI authentication and sandbox/config policy. Antigravity Visual Q&A is intentionally disabled by the supplied configuration. |
| AI Accept says stale | Any post-capture buffer edit/unload/rename invalidates proposal. Reselect current code and request a fresh edit. |
| `Ctrl-Space A` not received | Is tmux running and config sourced? Does Ghostty/macOS intercept Ctrl-Space? `tmux list-keys -T prefix`. |
| Popup hidden but agent still running | Expected. Use Show to return; Close inside popup to terminate. |
| `gd` / `K` not working | Confirm correct filetype, LSP process on PATH, `:LspInfo` or `:checkhealth vim.lsp`, and active buffer. |
| Formatting doesn't happen on save | Intentional: `Space uf` enables it per buffer; `Space cf` formats manually. |
| Treesitter doesn't highlight | Check installed parsers with `:TSInstall` / `:TSUpdate`, relevant filetype, toolchain. |
| No Markdown render | Open a Markdown buffer; check plugin load, `:RenderMarkdown buf_toggle`. |
| File explorer root surprises you | `Space e` uses Neovim's launch directory even after jumping to outside file definitions. |
| Git hunk keymaps absent | Gitsigns attaches only in applicable tracked buffers. |
| Ghostty background missing | Set actual image path and generated wallpaper config; `/Users/REPLACE_ME` values need substitution. |
| Keyboard mappings clash | Check `:verbose map`, `:verbose imap`, `:verbose xmap`, and `tmux list-keys`. |

---

---

## 15. How the AI integration works (advanced reference)

You do **not** need this section for ordinary programming. It documents the actual safety boundaries, selection formats, and process behavior so users can tell what is and is not guaranteed.

### Selection capture and its limits

`require("ai").get_selection()` captures a snapshot of the current Visual selection (or a just-exited selection that remains valid). It includes the text and lines, file path if named, buffer ID, `changedtick`, selection mode, line/column endpoints, and native per-row regions. An unnamed buffer has no file path. `:AISelectionInfo` shows a short diagnostic preview without making an AI request.

Coordinates refer to the **unsaved Neovim buffer**, not disk content. Lines and native byte columns are 1-based and selected byte endpoints are inclusive; for example `αβ` after two spaces in `  αβ foo` occupies byte columns 3–6. Unicode characters can occupy more than one byte. Selections with partial cells/virtual offsets and block selections are not eligible for AI edit application.

The implementation stores native `getregionpos(..., {eol=true})` locations, using `getregion()` to extract the text with indentation and whitespace preserved. It invalidates stale snapshots after applicable buffer changes. Selection text joins lines with LF without adding a trailing LF automatically.

### What the CLI receives

A Visual question includes your written question, exact selected code, file path when available, selected line interval, and filetype. The selected unsaved text is sent to the CLI over standard input, not by saving the buffer first. Named files use a detected project root (Git/Go/Cargo/npm where applicable), otherwise the containing directory; unnamed buffers use the current working directory. Codex may read other accessible repository files: **read-only** does not mean strictly limited to the selection.

The supplied Q&A and edit adapter invokes `codex exec` with an enforced read-only sandbox, no automatic approval, ephemeral execution and restrictions on inherited configuration/tool capabilities. Unsupported security flags cause an error, **not** a retry in a weaker sandbox. The interactive tmux Codex launch has its own read-only options and may use a different configuration context. Antigravity's interactive availability is checked separately; its Visual Q&A is disabled unless enforceable read-only mode can be verified.

### Request, answer, and proposal lifetimes

Non-interactive CLI execution is asynchronous and has a 120-second timeout. The implementation keeps input/output and review data in memory rather than writing prompt or response files. A `q` hide retains the answer/proposal and does not stop an in-progress request. Explicit Close/cancel actions stop the corresponding request; timers and the dedicated process group are cleaned up. A child that deliberately leaves that process group is outside the cleanup guarantee. Closing the entire editor cancels Visual Q&A, **not** a persistent tmux session.

One question/edit input or request can run at a time; newer valid proposals replace previous proposals. Hidden replies can be reopened until replaced, explicitly closed, or the editor exits. Requests and proposals are **not synchronized** with the tmux agent's interactive conversation.

### Proposal format and review guarantees

Codex is asked to provide a complete replacement enclosed in exact `AI_REPLACEMENT` markers. The integration removes those delimiters but preserves payload whitespace. Missing/extra delimiters, empty or whitespace-only payloads, NULs, code fences, diff headers, and likely explanatory prose are rejected; these are **format checks**, not verification that code is correct. Proposed code is never compiled or executed automatically.

Accept compares the buffer identity, loaded/normal/modifiable state, file path, captured mode, exact original text, byte boundaries, and `changedtick`. It edits only the original characterwise or linewise selection with a single undoable Neovim buffer change. It neither writes the file nor formats it. Any intervening change (even an unrelated one) can mark a proposal stale. An unloaded/wiped source cannot be accepted. File modifications performed **only on disk** may not be detected by the buffer snapshot check; review with Git before saving if another process may have changed the file.

After Accept the proposal is marked accepted and cannot be applied again. Reject discards it without changing source text. Hide retains the review; an obsolete viewer callback cannot accept a newer proposal.

### Persistent tmux sessions and project isolation

Each agent session is keyed by the origin tmux session ID, launching pane's physical current directory, and agent type. Session names have an integration-owned prefix and directory hash to avoid collisions. Show reattaches to a running session; Close terminates only that session. When an agent exits, reopening may start a new process instead of restoring its old in-memory conversation. Hiding preserves a running process but does not survive an entire tmux server stop or machine reboot.

A popup does not automatically follow whichever source file you later open in Neovim: it uses the tmux launching pane's working directory. To work in another project, launch from that directory. The popup is centered at roughly 85% of terminal width and height; `Ctrl-Space H` hides only the nested popup client. Normal Escape and Ctrl-C are passed to the agent UI.

### Privacy, setup, and diagnostics

The integration avoids writing its own transcript/prompt files, but the external CLI/provider may retain usage data according to its settings. Your selected code is sent to the provider when you submit an AI request. Do not submit secrets or private code without the appropriate permission. Read-only sandbox restrictions constrain command execution; they are not a general privacy guarantee.

A portable install needs the configuration in `nvim/`, the tmux config and `tmux/agent-popup`, a compatible Neovim version with `vim.pack`, and installed external tools. The provided Ghostty config contains machine-specific placeholder paths that need substitution. The original rollback script and local machine backups are **not distributed** with the supplied sources. For troubleshooting, use `:verbose map <Space>ae`, `:checkhealth`, `tmux list-keys -T prefix`, and the repo's Git history. Do not rely on an undocumented historical backup path.

### Plugins in this setup

Native `vim.pack` manages Treesitter, blink.cmp, mini.nvim, conform.nvim, gitsigns.nvim, and a Markdown-rendering plugin. `mini.nvim` supplies picker, explorer, extended text objects, surround operations, automatic pairs, animation, and buffer removal; only the configured modules are active. LSP servers and formatters are separate executable dependencies, not embedded in this repository. Plugin versions are recorded by the lockfile; update them deliberately with `:lua vim.pack.update()` and `:TSUpdate` where appropriate.

