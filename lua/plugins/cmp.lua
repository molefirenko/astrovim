return {
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.sources = cmp.config.sources({
        {name = "codeium", keyword_length = 3},
        {name = "luasnip", keyword_length = 2},
        {name = "nvim_lsp", keyword_length = 1},
        {name = "buffer", keyword_length = 3},
      })
    end,
  }
}
