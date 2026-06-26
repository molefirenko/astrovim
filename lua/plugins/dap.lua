return {
  "mfussenegger/nvim-dap",
  config = function(plugin, opts)
    require "astronvim.plugins.configs.nvim-dap"(plugin, opts)
    local dap = require "dap"
    dap.adapters.php = {
      type = "executable",
      command = "node",
      args = { os.getenv("HOME") .. "/.local/share/nvim/mason/packages/php-debug-adapter/extension/out/phpDebug.js" },
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
