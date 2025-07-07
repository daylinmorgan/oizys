return {
  {
    "LazyVim/LazyVim",
    version = false,
    opts = {
      colorscheme = "catppuccin",
    },
  },
  -- {
  --   "folke/noice.nvim",
  -- },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = vim.list_extend(opts.ensure_installed or {}, {
        "vim",
        "vimdoc",
        "html",
        "toml",
        "json",
        "yaml",

        "regex",
      })
    end,
  },
  {
    "saghen/blink.cmp",
    opts = {
      -- 'default' for mappings similar to built-in completion
      -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
      -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
      -- see the "default configuration" section below for full documentation on how to define
      -- your own keymap.
      keymap = { preset = "default" },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      -- cspell probably isn't installed globally? though could be with pnpm...
      -- linters_by_ft = {
      --   markdown = { "cspell" },
      -- },

      -- LazyVim extension to easily override linter options
      -- or add custom linters.
      ---@type table<string,table>
      linters = {
        -- -- Example of using selene only when a selene.toml file is present
        -- selene = {
        --   -- `condition` is another LazyVim extension that allows you to
        --   -- dynamically enable/disable linters based on the context.
        --   condition = function(ctx)
        --     return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
        --   end,
        -- },
        cspell = {
          -- only works for one file type?
          -- see lua/config/autocmds for a possible solution that includes more files
          condition = function(ctx)
            return vim.fs.find({ ".cspell.config.yaml" }, { path = ctx.filename, upward = true })[1]
          end,
        },
      },
    },
  },
  {
    "folke/ts-comments.nvim",
    opts = {
      lang = {
        nim = "# %s",
      },
    },
  },
}
