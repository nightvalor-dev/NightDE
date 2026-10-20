local map = vim.keymap.set

-- Basics
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR><Esc>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit window" })
map("n", "<leader>Q", "<cmd>qa<CR>", { desc = "Quit all" })

-- Move between splits with Ctrl + h/j/k/l
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Split vertically" })
map("n", "<leader>sh", "<cmd>split<CR>",  { desc = "Split horizontally" })

-- Resize splits with Ctrl + arrows
map("n", "<C-Up>",    "<cmd>resize +2<CR>",          { desc = "Taller" })
map("n", "<C-Down>",  "<cmd>resize -2<CR>",          { desc = "Shorter" })
map("n", "<C-Left>",  "<cmd>vertical resize -2<CR>", { desc = "Narrower" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Wider" })

-- Buffers (open files) with Shift + h/l
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>",     { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Close buffer" })

-- Move selected lines up/down, keep selection when indenting
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move lines down", silent = true })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move lines up", silent = true })
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Keep the cursor centred when jumping
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Paste over a selection without losing what you copied
map("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })

-- Diagnostics
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Previous diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end,  { desc = "Next diagnostic" })

-- Leave terminal mode with Esc Esc
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
