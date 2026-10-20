-- NightDE Neovim — entry point
-- Layout:
--   lua/config/options.lua   editor settings
--   lua/config/keymaps.lua   general keymaps (plugin keys live with each plugin)
--   lua/config/autocmds.lua  small automations
--   lua/config/lazy.lua      plugin manager bootstrap
--   lua/plugins/*.lua        one file per area, loaded automatically

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
