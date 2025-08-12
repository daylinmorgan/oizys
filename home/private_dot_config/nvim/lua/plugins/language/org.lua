return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    lazy = false,
    dependencies = {
      "akinsho/org-bullets.nvim",
    },
    config = function()
      -- Setup orgmode
      require("orgmode").setup({
        org_agenda_files = { "~/org/*", "~/orgs/**/*" },
        org_default_notes_file = "~/org/note.org",
      })
      require("org-bullets").setup() -- for the vibes ¯\_(ツ)_/¯
      -- NOTE: If you are using nvim-treesitter with ~ensure_installed = "all"~ option
      -- add ~org~ to ignore_install
      require("nvim-treesitter.configs").setup({
        ignore_install = { "org" },
      })
    end,
  },
}
