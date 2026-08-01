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
