
vim.filetype.add({
	extension = {
    roc = "roc",
		rv = "revo",
		revo = "revo",
	},
})

vim.lsp.config("revo", {
	cmd = { "revo", "lsp" },
	filetypes = { "rv", "revo" },
	root_markers = {
		"lib.json",
		"exe.json",
		".git",
	},
})

vim.lsp.enable("revo")

vim.treesitter.language.register("revo", {
	"rv",
	"revo",
})
