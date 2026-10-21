-- Colour schemes, driven by the NightDE theme switcher.
-- The active theme is read from ~/.config/nightde/current; running the switcher
-- calls NightdeTheme() in every open Neovim so they change live.

local function nightde_theme()
    local base = vim.fn.expand("~/.config/nightde")
    local name = "kanagawa"
    local f = io.open(base .. "/current", "r")
    if f then
        name = vim.trim(f:read("*a"))
        f:close()
    end
    local scheme = "kanagawa"
    local pf = io.open(base .. "/themes/" .. name .. "/palette.json", "r")
    if pf then
        local ok, palette = pcall(vim.json.decode, pf:read("*a"))
        pf:close()
        if ok and palette.nvim then scheme = palette.nvim end
    end
    return scheme
end

-- Global so the switcher can call it over Neovim's socket
function _G.NightdeTheme()
    local ok = pcall(vim.cmd.colorscheme, nightde_theme())
    if not ok then pcall(vim.cmd.colorscheme, "kanagawa") end
    return ""
end

return {
    -- Kanagawa, matched to the NightDE kitty theme:
    -- black #121212 background, dull red #7A3B3F selection, no separate gutter colour
    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            compile = false,
            theme = "wave",
            background = { dark = "wave", light = "lotus" },
            terminalColors = true,
            colors = {
                theme = {
                    all = {
                        ui = {
                            bg = "#121212", bg_dim = "#121212", bg_gutter = "none",
                            bg_m1 = "#0D0D0D", bg_m3 = "#0D0D0D", bg_p1 = "#1A1A1A",
                            bg_visual = "#7A3B3F",
                            float = { bg = "#121212", bg_border = "#121212" },
                        },
                    },
                },
            },
            overrides = function(colors)
                local theme = colors.theme
                return {
                    Visual          = { bg = "#7A3B3F" },
                    NormalFloat     = { bg = "#121212" },
                    FloatBorder     = { bg = "#121212", fg = "#54546D" },
                    FloatTitle      = { bg = "#121212", bold = true },
                    CursorLine      = { bg = "#1A1A1A" },
                    Pmenu           = { fg = theme.ui.shade0, bg = "#1A1A1A" },
                    PmenuSel        = { fg = "NONE", bg = "#7A3B3F" },
                    PmenuSbar       = { bg = "#1A1A1A" },
                    PmenuThumb      = { bg = "#54546D" },
                    TelescopeTitle         = { fg = theme.ui.special, bold = true },
                    TelescopePromptNormal  = { bg = "#1A1A1A" },
                    TelescopePromptBorder  = { fg = "#1A1A1A", bg = "#1A1A1A" },
                    TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = "#0D0D0D" },
                    TelescopeResultsBorder = { fg = "#0D0D0D", bg = "#0D0D0D" },
                    TelescopePreviewNormal = { bg = "#121212" },
                    TelescopePreviewBorder = { fg = "#121212", bg = "#121212" },
                    TelescopeSelection     = { bg = "#7A3B3F" },
                    NeoTreeNormal          = { bg = "#0D0D0D" },
                    NeoTreeNormalNC        = { bg = "#0D0D0D" },
                    WinSeparator           = { fg = "#2A2A37" },
                }
            end,
        },
        config = function(_, opts)
            require("kanagawa").setup(opts)
            _G.NightdeTheme()           -- pick the active NightDE theme at startup
        end,
    },

    -- Catppuccin Mocha — and "Ember", which is Catppuccin's Macchiato flavour
    -- recoloured with the Ember palette (Neovim has no ready-made Ember scheme)
    {
        "catppuccin/nvim",
        name = "catppuccin",
        lazy = true,
        opts = {
            term_colors = true,
            color_overrides = {
                macchiato = {
                    rosewater = "#FFDAD5", flamingo = "#FFC4BC", pink = "#F0A8C0", mauve = "#FFB4AB",
                    red = "#FF5449", maroon = "#FF897D", peach = "#FFB68E", yellow = "#E7C27D",
                    green = "#B5CC8E", teal = "#8CC7B5", sky = "#9ECFD6", sapphire = "#8FC1D9",
                    blue = "#A7B8E8", lavender = "#D8B4E8",
                    text = "#F1DEDC", subtext1 = "#D8C2BF", subtext0 = "#BFA9A6",
                    overlay2 = "#A08C8A", overlay1 = "#8A7472", overlay0 = "#735D5B",
                    surface2 = "#5A3B38", surface1 = "#4D3533", surface0 = "#392220",
                    base = "#220F0E", mantle = "#180A09", crust = "#120707",
                },
            },
            highlight_overrides = {
                mocha     = function() return { Visual = { bg = "#4B4466" }, PmenuSel = { bg = "#4B4466" } } end,
                macchiato = function() return { Visual = { bg = "#73332E" }, PmenuSel = { bg = "#73332E" } } end,
            },
            integrations = {
                blink_cmp = true, gitsigns = true, neotree = true, telescope = { enabled = true },
                treesitter = true, which_key = true, fidget = true, mason = true,
                indent_blankline = { enabled = true }, native_lsp = { enabled = true },
            },
        },
    },

    -- Everforest
    {
        "sainnhe/everforest",
        lazy = true,
        init = function()
            vim.g.everforest_background = "medium"
            vim.g.everforest_better_performance = 1
            vim.g.everforest_enable_italic = 1
        end,
    },
}
