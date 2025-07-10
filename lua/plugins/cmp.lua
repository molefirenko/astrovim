if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE
return {
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.sources = cmp.config.sources({
        {name = "luasnip", keyword_length = 2},
        {name = "nvim_lsp", keyword_length = 1},
        {name = "buffer", keyword_length = 3},
        {name = "codeium", keyword_length = 4},
      })
    end,
  }
}
