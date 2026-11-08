return {
  "mfussenegger/nvim-dap",
  config = function()
    require "astronvim.plugins.configs.nvim-dap"
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
        -- resolved by nvim-dap when each session starts, so it follows `:cd` changes
        pathMappings = {
          ["/var/www/html/"] = "${workspaceFolder}/",
        },
      },
    }
  end,
}
