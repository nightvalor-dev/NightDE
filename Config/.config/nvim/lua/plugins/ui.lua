return {
    -- Icons (needs a Nerd Font in the terminal; kitty already uses JetBrainsMono Nerd Font)
    { "nvim-tree/nvim-web-devicons", lazy = true },

    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = {
            options = {
                theme = "kanagawa",
                globalstatus = true,
                component_separators = { left = "", right = "" },
                section_separators   = { left = "", right = "" },
                disabled_filetypes = { statusline = { "neo-tree" } },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff" },
                lualine_c = { { "filename", path = 1 }, "diagnostics" },
                lualine_x = { "lsp_status", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
            },
        },
    },

    -- Open files as tabs along the top
    {
        "akinsho/bufferline.nvim",
        version = "*",
        event = "VeryLazy",
        opts = {
            options = {
                diagnostics = "nvim_lsp",
                always_show_bufferline = false,
                show_buffer_close_icons = false,
                separator_style = "thin",
                offsets = { { filetype = "neo-tree", text = "Files", highlight = "Directory", text_align = "left" } },
            },
        },
    },

    -- Indent guides
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            indent = { char = "│" },
            scope = { enabled = true, show_start = false, show_end = false },
            exclude = { filetypes = { "help", "neo-tree", "lazy", "mason" } },
        },
    },

    -- Shows pending keybinds after you press <leader>
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            preset = "modern",
            spec = {
                { "<leader>b", group = "buffer" },
                { "<leader>c", group = "code" },
                { "<leader>f", group = "find" },
                { "<leader>g", group = "git" },
                { "<leader>s", group = "split" },
                { "<leader>x", group = "diagnostics" },
            },
        },
    },

    -- LSP progress spinner in the corner
    { "j-hui/fidget.nvim", event = "LspAttach", opts = {} },
}
