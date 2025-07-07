return {
  require("util").setup_lang({ treesitter = { "bash" }, mason = { "shellcheck" } }),
  -- {
  --   "nvimtools/none-ls.nvim",
  --   opts = function(_, opts)
  --     local nls = require("null-ls")
  --     opts.sources = vim.list_extend(opts.sources or {}, {
  --       nls.builtins.diagnostics.shellcheck,
  --     })
  --   end,
  -- },
}
