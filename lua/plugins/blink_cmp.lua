return {
  {
    "saghen/blink.cmp",
    dependencies = {
      {
        "Exafunction/windsurf.nvim",
      },
    },
    opts = {
      signature = { enabled = true },
      sources = {
        default = { "codeium" },
        providers = {
          codeium = { name = "Codeium", module = "codeium.blink", async = true },
        },
      },
    },
  },
}
