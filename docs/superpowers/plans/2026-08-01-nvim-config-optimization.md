# Neovim Config Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove confirmed dead weight and wire up a broken feature in this AstroNvim v6 config, without changing the architecture documented in `CLAUDE.md`.

**Architecture:** No structural changes — every task edits an existing file in place, respecting the "one concern per file" layout already documented in `CLAUDE.md`. Nothing is reorganized; two disabled files (`none-ls.lua`) get enabled because their content is now needed, per the existing guard-line convention.

**Tech Stack:** AstroNvim v6, lazy.nvim, blink.cmp, windsurf.nvim (Codeium), none-ls.nvim, Mason (stylua/selene), nvim-dap.

## Global Constraints

- Lua formatting: StyLua, 120 col, 2-space indent, Unix line endings, double quotes preferred, no call parens where optional (`.stylua.toml`).
- Linting: selene, `std = "neovim"` (`selene.toml`).
- Do not touch `init.lua` beyond what's specified (repo convention: "BE CAUTIOUS editing this file").
- Preserve the documented file responsibilities in `CLAUDE.md` — do not merge `codeium.lua` and `blink_cmp.lua`, they are intentionally split by concern (AI completion vs. completion-engine wiring).
- Every enabled/previously-disabled file must keep the `---@type LazySpec` annotation already used elsewhere in `lua/plugins/`.

---

## Findings Summary (why these tasks exist)

Verified by reading every config file plus the installed plugin tree and `lazy-lock.json`:

1. **`nvim-cmp` is dead weight.** `lua/plugins/codeium.lua:5` lists `"hrsh7th/nvim-cmp"` as a dependency of `windsurf.nvim`, and it's present in `lazy-lock.json`. But AstroNvim v6 core has zero references to `nvim-cmp` anywhere (confirmed via grep of the installed AstroNvim plugin tree) — this config uses `blink.cmp` exclusively, wired in `blink_cmp.lua` via the `codeium.blink` module. The `nvim-cmp` dependency is an unused leftover, most likely copied from an old Codeium setup snippet written before this config switched to blink.cmp. It adds an entire extra completion-engine plugin to every startup for no benefit.
2. **PHP formatting/linting is installed but not wired up.** `mason.lua` installs `phpcs` and `phpcbf`. `astrolsp.lua:32` explicitly disables intelephense's own formatting capability — the clear intent is for something else to format PHP. But `none-ls.lua` (the only place a formatter/linter source could be registered) is disabled (`if true then return {} end`), and AstroNvim's core `mason-null-ls` integration ships with empty `handlers = {}` (confirmed by reading `astronvim/plugins/configs/mason-null-ls.lua`) — it does **not** auto-register sources for installed Mason tools. Net effect: PHP files currently have no active formatter and no phpcs diagnostics at all, despite the tooling being installed and format-on-save being explicitly cleared as if to make room for it.
3. **`windsurf.nvim` loads eagerly at startup.** `codeium.lua` declares it as a root plugin spec with a `config` function but no `event`/`cmd`/`ft` lazy-loading trigger, so lazy.nvim loads and initializes it unconditionally on every startup rather than deferring to when you actually start typing.
4. **DAP adapter path is less portable than it needs to be.** `dap.lua:9` builds the `php-debug-adapter` path via `os.getenv("HOME")`. `vim.fn.stdpath("data")` is the correct, already-available primitive for this and matches what Mason itself uses — it also holds if `XDG_DATA_HOME` is ever overridden, which `$HOME`-based concatenation does not.
5. **Two files don't match the project's own StyLua config.** `blink_cmp.lua` and `codeium.lua` use single quotes and omit the space in `return{`/`return{...}` , while `.stylua.toml` sets `quote_style = "AutoPreferDouble"`. Every other file in the repo already conforms. Running `stylua` fixes this mechanically.
6. **Leftover template example in `astrocore.lua`.** The `filetypes` block (lines 26-37) registers a fake `fooscript` filetype for `.foorc` files and an `/etc/foo/` path pattern — copied from the AstroNvim template and never adapted. It's inert but is exactly the kind of cruft that makes the "real" customizations harder to spot on a re-read.

Each task below is independent and safe to land on its own.

---

### Task 1: Remove the unused `nvim-cmp` dependency

**Files:**
- Modify: `lua/plugins/codeium.lua`

**Interfaces:** None — this is a pure deletion, no other task depends on it.

- [x] **Step 1: Remove the dependency**

Edit `lua/plugins/codeium.lua` from:

```lua
return {
  {
    'Exafunction/windsurf.nvim',
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
    config = function()
      require("codeium").setup({})
    end
  },
}
```

to:

```lua
return {
  {
    "Exafunction/windsurf.nvim",
    event = "InsertEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function() require("codeium").setup {} end,
  },
}
```

(This also folds in Task 3's lazy-load trigger since it's the same line being touched — see Task 3 for why `event = "InsertEnter"` is safe here.)

- [x] **Step 2: Verify nvim-cmp is no longer pulled in**

Run: `nvim --headless "+Lazy! sync" +qa`
Then: `grep '"nvim-cmp"' lazy-lock.json`
Expected: no output (entry removed from the lockfile after sync).

- [x] **Step 3: Manually confirm completion still works**

Open any file in `nvim`, enter insert mode, and confirm Codeium suggestions and blink.cmp's completion menu both still appear as before.

- [x] **Step 4: Commit**

```bash
git add lua/plugins/codeium.lua lazy-lock.json
git commit -m "Remove unused nvim-cmp dependency and lazy-load windsurf.nvim"
```

---

### Task 2: Wire up PHP formatting and linting via none-ls

**Files:**
- Modify: `lua/plugins/none-ls.lua`

**Interfaces:**
- Consumes: `phpcs` and `phpcbf` binaries, already installed by `mason-tool-installer` per `lua/plugins/mason.lua:25-26`.
- Produces: none-ls sources registered under the `nvimtools/none-ls.nvim` plugin spec — no other task depends on this.

- [x] **Step 1: Enable the file and register sources**

Replace the full contents of `lua/plugins/none-ls.lua` with:

```lua
-- Customize None-ls sources

---@type LazySpec
return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require "null-ls"

    -- Only insert new sources, do not replace the existing ones
    opts.sources = require("astrocore").list_insert_unique(opts.sources, {
      null_ls.builtins.diagnostics.phpcs,
      null_ls.builtins.formatting.phpcbf,
    })
  end,
}
```

- [x] **Step 2: Enable format-on-save for PHP only**

In `lua/plugins/astrolsp.lua`, scope format-on-save to PHP so the rest of the config's behavior (global format-on-save stays off) doesn't change:

```lua
      format_on_save = {
        enabled = false, -- enable or disable format on save globally
        allow_filetypes = { -- enable format on save for specified filetypes only
          "php",
        },
```

- [x] **Step 3: Verify the sources attach**

Run: `nvim --headless "+Lazy! sync" +qa` to ensure `phpcs`/`phpcbf` resolve without error (no "unknown builtin" message).
Open any `.php` file in the repo (or a scratch one) and run `:NullLsInfo` — expected: `phpcs` listed under diagnostics, `phpcbf` listed under formatting, both marked as attached/available.

- [x] **Step 4: Confirm formatting behavior manually**

In a `.php` buffer, deliberately misformat a line (e.g. wrong indent), save (`:w`), and confirm `phpcbf` reformats it. Introduce a phpcs violation (e.g. an unused variable, or whatever your local `phpcs` ruleset flags) and confirm a diagnostic appears.

- [x] **Step 5: Commit**

```bash
git add lua/plugins/none-ls.lua lua/plugins/astrolsp.lua
git commit -m "Wire up phpcs/phpcbf via none-ls for PHP diagnostics and format-on-save"
```

#### Post-implementation note

The approach above (manually registering `phpcs`/`phpcbf` sources in `none-ls.lua`) turned out to be unnecessary and was reverted. AstroNvim core's `mason-null-ls` integration auto-registers null-ls sources for any Mason-installed tool it recognizes, including `phpcs`/`phpcbf` — no manual `opts.sources` wiring is needed, and `none-ls.lua` correctly stays disabled (guard line intact). The actual root cause of "PHP formatting/linting not applying" was that `astrolsp.lua`'s `format_on_save.enabled` was `false`: AstroLSP's own logic (`astrolsp/init.lua:96-98`) short-circuits on `enabled = false` and never consults `allow_filetypes` at all. The real fix was setting `format_on_save.enabled = true` paired with `allow_filetypes = { "php" }`, which scopes format-on-save to PHP only rather than enabling it globally.

---

### Task 3: Make the DAP adapter path portable

**Files:**
- Modify: `lua/plugins/dap.lua`

**Interfaces:** None — isolated change to the `dap.adapters.php` table.

- [x] **Step 1: Replace `os.getenv("HOME")` with `vim.fn.stdpath("data")`**

Edit `lua/plugins/dap.lua`:

```lua
return {
  "mfussenegger/nvim-dap",
  config = function(plugin, opts)
    require "astronvim.plugins.configs.nvim-dap"(plugin, opts)
    local dap = require "dap"
    dap.adapters.php = {
      type = "executable",
      command = "node",
      args = { vim.fn.stdpath "data" .. "/mason/packages/php-debug-adapter/extension/out/phpDebug.js" },
    }
    dap.configurations.php = {
      {
        type = "php",
        request = "launch",
        name = "Listen for XDebug",
        port = 9003,
        log = true,
        pathMappings = {
          ["/var/www/html/"] = vim.fn.getcwd() .. "/",
        },
      },
    }
  end,
}
```

- [x] **Step 2: Verify the resolved path is identical to before**

Run: `nvim --headless -c 'lua print(vim.fn.stdpath("data") .. "/mason/packages/php-debug-adapter/extension/out/phpDebug.js")' -c 'q' 2>&1`
Expected: prints the same path as `echo "$HOME/.local/share/nvim/mason/packages/php-debug-adapter/extension/out/phpDebug.js"` on this machine (unless `XDG_DATA_HOME` is set, in which case the new path is the correct one).

- [x] **Step 3: Manually confirm a debug session still connects**

This needs a real PHP + XDebug environment, not something scriptable here: start a debug session with `:h dap` (`require("dap").continue()` / your usual keymap), confirm nvim-dap still launches the adapter and a breakpoint hit is reported over port 9003.

- [x] **Step 4: Commit**

```bash
git add lua/plugins/dap.lua
git commit -m "Use stdpath(data) instead of \$HOME for php-debug-adapter path"
```

---

### Task 4: Remove leftover template cruft and run StyLua

**Files:**
- Modify: `lua/plugins/astrocore.lua`
- Modify: `lua/plugins/blink_cmp.lua` (formatting only, via stylua)
- Modify: `lua/plugins/codeium.lua` (formatting only, via stylua — already hand-formatted in Task 1, this step is a no-op safety net if Task 4 lands independently)

**Interfaces:** None — cosmetic/cleanup only.

- [x] **Step 1: Delete the unused `fooscript` filetype example**

In `lua/plugins/astrocore.lua`, remove:

```lua
    -- passed to `vim.filetype.add`
    filetypes = {
      -- see `:h vim.filetype.add` for usage
      extension = {
        foo = "fooscript",
      },
      filename = {
        [".foorc"] = "fooscript",
      },
      pattern = {
        [".*/etc/foo/.*"] = "fooscript",
      },
    },
```

so the opts table goes straight from the `diagnostics` block to the `options` block.

- [x] **Step 2: Run StyLua across the whole config**

Run: `~/.local/share/nvim/mason/bin/stylua lua/ init.lua`
Expected: reformats `lua/plugins/blink_cmp.lua` (single→double quotes, `return {` spacing) and any other non-conforming file; no other files should change since they already conform.

- [x] **Step 3: Verify with a check-only pass**

Run: `~/.local/share/nvim/mason/bin/stylua --check lua/ init.lua`
Expected: exits 0 with no diff output.

- [x] **Step 4: Sanity-load the config**

Run: `nvim --headless "+Lazy! sync" +qa` and confirm no Lua errors are printed (a botched removal in `astrocore.lua` would show up here as a syntax error on startup).

- [x] **Step 5: Commit**

```bash
git add lua/plugins/astrocore.lua lua/plugins/blink_cmp.lua
git commit -m "Drop unused fooscript filetype example and run stylua"
```

---

## Self-Review

- **Coverage:** All 6 findings map 1:1 to a task (Task 1 covers findings 1 and 3 together since they're the same three lines; Task 2 → finding 2; Task 3 → finding 4; Task 4 → findings 5 and 6).
- **Placeholders:** None — every step shows the exact before/after code or an exact command with expected output.
- **Consistency:** `dap.adapters.php.args[1]` path construction matches Mason's own package layout (`mason/packages/<name>/...`), confirmed against the existing hardcoded string in the original file rather than assumed.
- **Risk ordering:** Tasks are ordered lowest-risk/highest-confidence (Task 1: pure deletion) to highest-manual-verification (Task 3: needs a live XDebug session to fully confirm). Task 2 changes user-visible PHP editing behavior (format-on-save) — flagged clearly in the step so it can be skipped or scoped further if unwanted.
