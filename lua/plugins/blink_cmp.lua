return{
  {
    'saghen/blink.cmp',
    dependencies = {
      {
        'Exafunction/windsurf.nvim',
      },
    },
    opts = {
      sources = {
        default = { 'codeium' },
        providers = {
          codeium = { name = 'Codeium', module = 'codeium.blink', async = true },
        },
      },
    },
  }
}
