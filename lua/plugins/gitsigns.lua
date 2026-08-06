-- Customize gitsigns.nvim

---@type LazySpec
return {
  "lewis6991/gitsigns.nvim",
  opts = function(_, opts)
    return require("astrocore").extend_tbl(opts, {
      current_line_blame = true,
    })
  end,
}
