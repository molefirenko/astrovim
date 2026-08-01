# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Neovim configuration built on [AstroNvim v6](https://github.com/AstroNvim/AstroNvim). It uses [lazy.nvim](https://github.com/folke/lazy.nvim) as the plugin manager. The primary development language is PHP, with supporting tooling for Lua config editing.

## Architecture

The load order is: `init.lua` → `lua/lazy_setup.lua` → `lua/community.lua` → `lua/plugins/*.lua` → `lua/polish.lua`.

- **`init.lua`** — bootstraps lazy.nvim, then wires in the PHP DAP adapter (XDebug on port 9003) with path mapping `/var/www/html/` ↔ `cwd`.
- **`lua/lazy_setup.lua`** — calls `lazy.setup()` with AstroNvim v6 pinned, imports community and plugins, sets `<Space>` as leader and `,` as localleader.
- **`lua/community.lua`** — disabled by default (guard line at top); enable to import AstroCommunity packs.
- **`lua/plugins/`** — user overrides, one concern per file:
  - `astrocore.lua` — vim options, buffer keymaps, diagnostics config.
  - `astrolsp.lua` — LSP feature flags, formatting (intelephense formatting is disabled), codelens autocommands. Format-on-save is enabled but scoped to PHP only (`format_on_save.enabled = true` with `allow_filetypes = { "php" }`).
  - `mason.lua` — auto-installed Mason packages: `lua-language-server`, `intelephense`, `stylua`, `php-debug-adapter`, `phpcs`, `phpcbf`. `phpcs`/`phpcbf` are auto-wired as null-ls sources by AstroNvim core's mason-null-ls integration, so `none-ls.lua` intentionally stays disabled — no manual source registration is needed there.
  - `treesitter.lua` — parsers auto-install enabled; ensures lua, vim, php, html, css.
  - `codeium.lua` — Windsurf (Codeium) AI completion via `Exafunction/windsurf.nvim`.
  - `blink_cmp.lua` — configures blink.cmp to surface Codeium as a completion source.
  - `dap.lua` — extends nvim-dap config: registers the PHP adapter (Mason-installed `php-debug-adapter`) and XDebug launch configuration on port 9003.
  - `astroui.lua` — disabled by default (guard line); colorscheme and icon overrides.
  - `none-ls.lua` — disabled by default (guard line); none-ls source additions go here.
  - `user.lua` — disabled by default (guard line); template for adding arbitrary plugins.
- **`lua/polish.lua`** — disabled by default (guard line); runs last for anything that doesn't fit elsewhere.

## Enabling Disabled Files

Several files have a guard `if true then return {} end` (or `if true then return end`) at the top. Remove that line to activate the file.

## Code Style

Lua formatting is enforced by **StyLua** with the settings in `.stylua.toml`:
- 120-character column width, 2-space indent, Unix line endings, double quotes preferred, no call parentheses where optional.

Linting uses **selene** (`selene.toml`) with `std = "neovim"` and several rules relaxed (global_usage, mixed_table, etc.).

## Adding Plugins

Add new plugin specs to `lua/plugins/` as new files or inside an existing file. Each file must return a `LazySpec` table. For AstroNvim-specific overrides, extend `AstroNvim/astrocore`, `AstroNvim/astrolsp`, or `AstroNvim/astroui` opts — lazy.nvim merges multiple spec entries for the same plugin.

## DAP / Debugging

The PHP debug adapter is configured in `lua/plugins/dap.lua` using the Mason-installed `php-debug-adapter`. It listens on port 9003 for XDebug connections. The `pathMappings` entry maps the container path `/var/www/html/` to the current working directory — adjust this if the project root differs.

The file extends `mfussenegger/nvim-dap`'s `config` function, so it explicitly calls `require "astronvim.plugins.configs.nvim-dap"` first to preserve AstroNvim's vscode `launch.json` parser before appending the PHP-specific setup.
