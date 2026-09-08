return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      local_parsers = {
        revo = {
          source = {
            type = "git",
            url = "https://codeberg.org/doomy/tree-sitter-revo",
            revision = "main",
          },
          filetype = "revo",
        },
      },
      ensure_installed = { "revo" },
    },
  },
}
