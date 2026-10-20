-- Kanagawa, matched to the NightDE kitty theme:
-- black #121212 background, dull red #7A3B3F selection, no separate gutter colour
return {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
        compile = false,
        theme = "wave",
        background = { dark = "wave", light = "lotus" },
        dimInactive = false,
        terminalColors = true,
        colors = {
            theme = {
                all = {
                    ui = {
                        bg         = "#121212",
                        bg_dim     = "#121212",
                        bg_gutter  = "none",
                        bg_m1      = "#0D0D0D",
                        bg_m3      = "#0D0D0D",
                        bg_p1      = "#1A1A1A",
                        bg_visual  = "#7A3B3F",
                        float      = { bg = "#121212", bg_border = "#121212" },
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
                -- Popup menu: dark, with the selection in the same dull red
                Pmenu           = { fg = theme.ui.shade0, bg = "#1A1A1A" },
                PmenuSel        = { fg = "NONE", bg = "#7A3B3F" },
                PmenuSbar       = { bg = "#1A1A1A" },
                PmenuThumb      = { bg = "#54546D" },
                -- Telescope: borderless blocks
                TelescopeTitle         = { fg = theme.ui.special, bold = true },
                TelescopePromptNormal  = { bg = "#1A1A1A" },
                TelescopePromptBorder  = { fg = "#1A1A1A", bg = "#1A1A1A" },
                TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = "#0D0D0D" },
                TelescopeResultsBorder = { fg = "#0D0D0D", bg = "#0D0D0D" },
                TelescopePreviewNormal = { bg = "#121212" },
                TelescopePreviewBorder = { fg = "#121212", bg = "#121212" },
                TelescopeSelection     = { bg = "#7A3B3F" },
                -- File tree blends into the editor
                NeoTreeNormal          = { bg = "#0D0D0D" },
                NeoTreeNormalNC        = { bg = "#0D0D0D" },
                WinSeparator           = { fg = "#2A2A37" },
            }
        end,
    },
    config = function(_, opts)
        require("kanagawa").setup(opts)
        vim.cmd.colorscheme("kanagawa")
    end,
}
