local o = vim.opt

-- Look
o.number = true
o.relativenumber = false
o.cursorline = true
o.signcolumn = "yes" -- no jumping when diagnostics/git signs appear
o.termguicolors = true
o.showmode = false -- lualine shows the mode
o.laststatus = 3 -- one statusline for all splits
o.wrap = false
o.scrolloff = 8
o.sidescrolloff = 8
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
o.fillchars = { eob = " " } -- hide ~ on empty lines
o.pumheight = 12

-- Editing
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4
o.smartindent = true
o.breakindent = true
o.clipboard = "unnamedplus" -- system clipboard (needs wl-clipboard)
o.mouse = "a"
o.undofile = true -- undo survives closing the file
o.swapfile = false
o.confirm = true -- ask instead of failing on :q with changes

-- Search
o.ignorecase = true
o.smartcase = true
o.inccommand = "split" -- live preview of :s substitutions

-- Splits / timing
o.splitright = true
o.splitbelow = true
o.updatetime = 250
o.timeoutlen = 400

-- Diagnostics: icons in the gutter, rounded floats
vim.diagnostic.config({
	severity_sort = true,
	virtual_text = { spacing = 2, prefix = "●" },
	float = { border = "rounded", source = "if_many" },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚 ",
			[vim.diagnostic.severity.WARN] = "󰀪 ",
			[vim.diagnostic.severity.INFO] = "󰋽 ",
			[vim.diagnostic.severity.HINT] = "󰌶 ",
		},
	},
})
