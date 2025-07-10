return{
  {
    'saghen/blink.cmp',
    dependencies = {
      {
        'Exafunction/codeium.nvim',
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
