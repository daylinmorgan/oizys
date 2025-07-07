return {
  require("util").setup_lang({ treesitter = { "nim", "nim_format_string" } }),
  -- lsp = { "nim_langserver" } }),
  --
  -- {
  --   "neovim/nvim-lspconfig",
  --   opts = {
  --     servers = {
  --       nim_langserver = {
  --         -- enabled = true,
  --         nim = {
  --           maxNimsuggestProcesses = 3,
  --         },
  --       },
  --     },
  --   },
  -- },
}
