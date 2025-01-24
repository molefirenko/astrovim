-- DAP xdebug configuration
return {
  "jay-babu/mason-nvim-dap.nvim",
  configurations = {
    {
      -- add more arguments for adding more debuggers
      name = "Listen for Xdebug",
      type = "php",
      request = "launch",
      port = 9003,
      pathMappings = {
        ['/var/www/html/'] = "${workspaceFolder}",
      },
      log = true,
    }
  }
}

