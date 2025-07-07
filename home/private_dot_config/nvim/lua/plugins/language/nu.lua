return {
  -- https://github.com/nushell/tree-sitter-nu/blob/dc22e2577eb09d1d0de50802c59da2eca98a0e7b/installation/neovim.md
  "nvim-treesitter/nvim-treesitter",
    config = function()
        require("nvim-treesitter.configs").setup {
            ensure_installed = { "nu" }, -- Ensure the "nu" parser is installed
            highlight = {
                enable = true,            -- Enable syntax highlighting
            },
            -- OPTIONAL!! These enable ts-specific textobjects.
            -- So you can hit `yaf` to copy the closest function,
            -- `dif` to clear the content of the closest function,
            -- or whatever keys you map to what query.
            textobjects = {
                select = {
                    enable = true,
                    keymaps = {
                        -- You can use the capture groups defined in textobjects.scm
                        -- For example:
                        -- Nushell only
                        ["aP"] = "@pipeline.outer",
                        ["iP"] = "@pipeline.inner",

                        -- supported in other languages as well
                        ["af"] = "@function.outer",
                        ["if"] = "@function.inner",
                        ["al"] = "@loop.outer",
                        ["il"] = "@loop.inner",
                        ["aC"] = "@conditional.outer",
                        ["iC"] = "@conditional.inner",
                        ["iS"] = "@statement.inner",
                        ["aS"] = "@statement.outer",
                    }, -- keymaps
                }, -- select
            }, -- textobjects
        }
    end,
    dependencies = {
        -- Install official queries and filetype detection
        -- alternatively, see section "Install official queries only"
        { "nushell/tree-sitter-nu" },
    },
    build = ":TSUpdate",
}
