-- Customize None-ls sources
--
-- Sources for Mason-installed tools (phpcs, phpcbf, prettier) are registered automatically by
-- mason-null-ls (wired in AstroNvim core). Only overrides of those defaults belong here.

---@type LazySpec
return {
  "jay-babu/mason-null-ls.nvim",
  opts = {
    handlers = {
      -- phpcs defaults to linting on every text change, spawning a process per typing pause.
      -- Run it on save instead to keep editing responsive on large rulesets.
      phpcs = function()
        local null_ls = require "null-ls"
        null_ls.register(null_ls.builtins.diagnostics.phpcs.with { method = null_ls.methods.DIAGNOSTICS_ON_SAVE })
      end,
    },
  },
}
