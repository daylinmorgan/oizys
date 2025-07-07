return {
  require("util").setup_lang({ treesitter = { "lua" }, mason = { "stylua", "lua-language-server" } }),
  -- {
  --   "nvimtools/none-ls.nvim",
  --   opts = function(_, opts)
  --     local nls = require("null-ls")
  --     opts.sources = vim.list_extend(opts.sources or {}, {
  --       nls.builtins.formatting["stylua"],
  --     })
  --   end,
  -- },
}
