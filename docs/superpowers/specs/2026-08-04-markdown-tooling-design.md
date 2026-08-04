# Markdown Tooling: Preview, Table Formatting, PDF Export

Date: 2026-08-04

## Goal

Add three markdown-editing capabilities to this AstroNvim v6 config:

1. In-editor markdown preview (including tables).
2. On-demand markdown/table formatting.
3. Export the current markdown buffer to PDF.

## Environment constraints

Verified present: `npm`/`node` (via nvm), `google-chrome`.
Verified absent: `pandoc`, `glow`, `wkhtmltopdf`, `weasyprint`, any LaTeX engine.

Design deliberately avoids requiring new system packages — everything
routes through Mason (already used for `intelephense`, `stylua`, `phpcs`,
`phpcbf`, `php-debug-adapter`) or `npx` (already have Node).

## Components

### 1. In-editor preview — `markview.nvim`

- Plugin: `OXY2DEV/markview.nvim`.
- Pure Lua, treesitter-based, renders directly in the buffer (headers,
  tables, code blocks, task lists). No external process, no browser, works
  over SSH.
- Lazy-loads on `ft = "markdown"`.
- Requires `markdown` and `markdown_inline` treesitter parsers (`html` is
  already installed, which markview also uses for embedded HTML).
- Toggled per-buffer via `<Leader>mp`.

### 2. On-demand table/document formatting — `prettier` via none-ls

- Reuses the existing formatting pipeline: Mason installs the tool,
  mason-null-ls auto-wires it as a none-ls source — the same mechanism
  already in place for `phpcs`/`phpcbf`.
- `prettier` added to `mason-tool-installer` in `mason.lua`.
- `none-ls.lua` guard removed (currently disabled); registers
  `null_ls.builtins.formatting.prettier` scoped to
  `filetypes = { "markdown" }` only — it must not affect PHP or Lua
  formatting.
- **On-demand only, not on save.** `markdown` is NOT added to
  `astrolsp.lua`'s `formatting.format_on_save.allow_filetypes` (which
  stays PHP-only). A buffer-local keymap `<Leader>mf` calls
  `vim.lsp.buf.format({ async = true })` to format manually.

### 3. PDF export — `npx md-to-pdf`

- No persistent install. Buffer-local keymap `<Leader>me` shells out
  asynchronously (`vim.system`) to `npx md-to-pdf <current-file>`.
- `md-to-pdf` is Puppeteer-based; on first run `npx` downloads it into the
  npm cache (already have Node/npm) and Puppeteer drives headless Chrome
  (the existing `google-chrome` install, or Puppeteer's bundled Chromium
  if it can't find/use the system one).
- Output: `<file>.pdf` written next to the source `.md` file.
- `vim.notify` on start, success (with output path), and failure (with
  stderr excerpt). Must not block the editor — command runs
  asynchronously; a second invocation while one is already running for
  the same buffer is not specially guarded against (rare, low-cost
  footgun given this is a manual, human-paced action).

## File changes

| File | Change |
| --- | --- |
| `lua/plugins/treesitter.lua` | Add `"markdown"`, `"markdown_inline"` to `ensure_installed` |
| `lua/plugins/mason.lua` | Add `"prettier"` to the formatters list |
| `lua/plugins/none-ls.lua` | Remove disable guard; register `prettier` source scoped to `filetypes = { "markdown" }` |
| `lua/plugins/markdown.lua` (new) | `markview.nvim` spec; `AstroNvim/astrocore` opts merge adding a `FileType markdown` autocmd (group `markdown_tools`, following the pattern `astrolsp.lua` uses for `lsp_codelens_refresh`) that sets three buffer-local keymaps: `<Leader>mf` (format), `<Leader>mp` (toggle preview), `<Leader>me` (export PDF) |
| `lua/plugins/astrocore.lua` | Add `<Leader>m` which-key group label ("Markdown") |
| `/home/maxim/Documents/lsp-cheatsheet.md` (external, already done) | New "Markdown Tools" section documenting the three keymaps |

## Explicitly out of scope

- Format-on-save for markdown (user wants on-demand only).
- Browser-based live preview (in-editor rendering was chosen instead).
- `pandoc`/LaTeX-based PDF export (avoided to skip new system-package
  installs).
- PDF export customization (themes, page size, headers/footers) —
  `md-to-pdf` defaults are used as-is.
