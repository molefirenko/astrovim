-- Markdown tooling: in-editor preview, on-demand table/document formatting, PDF export
-- See docs/superpowers/specs/2026-08-04-markdown-tooling-design.md for the design rationale

---@type LazySpec
return {
  {
    "OXY2DEV/markview.nvim",
    ft = "markdown",
    opts = {},
  },
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      autocmds = {
        markdown_tools = {
          {
            event = "FileType",
            pattern = "markdown",
            desc = "Markdown buffer-local keymaps (format/preview/export)",
            callback = function(args)
              local bufnr = args.buf

              vim.keymap.set(
                "n",
                "<Leader>mf",
                function() vim.lsp.buf.format { async = true, bufnr = bufnr } end,
                { buffer = bufnr, desc = "Format markdown (prettier)" }
              )

              vim.keymap.set(
                "n",
                "<Leader>mp",
                function() vim.cmd "Markview toggle" end,
                { buffer = bufnr, desc = "Toggle markdown preview" }
              )

              vim.keymap.set("n", "<Leader>me", function()
                local src = vim.api.nvim_buf_get_name(bufnr)
                if src == "" then
                  vim.notify("Save the buffer before exporting to PDF", vim.log.levels.WARN)
                  return
                end

                vim.notify("Exporting " .. vim.fn.fnamemodify(src, ":t") .. " to PDF...", vim.log.levels.INFO)
                vim.system({ "npx", "md-to-pdf", src }, { text = true }, function(result)
                  vim.schedule(function()
                    if result.code == 0 then
                      local pdf = vim.fn.fnamemodify(src, ":r") .. ".pdf"
                      vim.notify("Exported to " .. pdf, vim.log.levels.INFO)
                    else
                      vim.notify("PDF export failed:\n" .. (result.stderr or "unknown error"), vim.log.levels.ERROR)
                    end
                  end)
                end)
              end, { buffer = bufnr, desc = "Export markdown to PDF" })
            end,
          },
        },
      },
    },
  },
}
