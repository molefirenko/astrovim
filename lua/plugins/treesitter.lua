-- Customize Treesitter

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      "lua",
      "vim",
      "php",
      "html",
      "css",
      "javascript",
      -- add more arguments for adding more treesitter parsers
    },
  },
}
