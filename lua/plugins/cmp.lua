return {
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.source = cmp.config.sources({
        {name = "codeium"}
      })
    end,
  }
}
