return {
  require("util").setup_lang({ treesitter = { "nix" } }),
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nixd = {
          mason = false,
        },
        -- nil_ls = {
        -- mason = false,
        -- },
      },
    },
  },
}
