return {
    -- File tree
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        cmd = "Neotree",
        dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", "nvim-tree/nvim-web-devicons" },
        keys = {
            { "<leader>e", "<cmd>Neotree toggle reveal<CR>", desc = "File tree" },
        },
        opts = {
            close_if_last_window = true,
            popup_border_style = "rounded",
            filesystem = {
                follow_current_file = { enabled = true },
                use_libuv_file_watcher = true,
                filtered_items = { hide_dotfiles = false, hide_gitignored = false },
            },
            window = { width = 32 },
        },
    },

    -- Fuzzy finder
    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
        keys = {
            { "<leader>ff", "<cmd>Telescope find_files<CR>",  desc = "Find files" },
            { "<leader>fg", "<cmd>Telescope live_grep<CR>",   desc = "Search text in project" },
            { "<leader>fb", "<cmd>Telescope buffers<CR>",     desc = "Open buffers" },
            { "<leader>fr", "<cmd>Telescope oldfiles<CR>",    desc = "Recent files" },
            { "<leader>fh", "<cmd>Telescope help_tags<CR>",   desc = "Help pages" },
            { "<leader>fk", "<cmd>Telescope keymaps<CR>",     desc = "Keymaps" },
            { "<leader>fw", "<cmd>Telescope grep_string<CR>", desc = "Word under cursor" },
            { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
            { "<leader><leader>", "<cmd>Telescope find_files<CR>", desc = "Find files" },
        },
        config = function()
            local telescope = require("telescope")
            telescope.setup({
                defaults = {
                    prompt_prefix = "   ",
                    selection_caret = " ",
                    sorting_strategy = "ascending",
                    layout_config = { prompt_position = "top", width = 0.9, height = 0.85 },
                    file_ignore_patterns = { "%.git/", "node_modules/", "vendor/" },
                },
                pickers = { find_files = { hidden = true } },
            })
            pcall(telescope.load_extension, "fzf")
        end,
    },

    -- Auto-close brackets and quotes
    { "windwp/nvim-autopairs", event = "InsertEnter", opts = { check_ts = true } },

    -- Add/change/delete surrounding pairs: ysiw" , cs"' , ds"
    { "kylechui/nvim-surround", version = "*", event = "VeryLazy", opts = {} },

    -- Highlight TODO / FIXME / NOTE comments
    {
        "folke/todo-comments.nvim",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {},
        keys = {
            { "<leader>ft", "<cmd>TodoTelescope<CR>", desc = "TODOs" },
        },
    },

    -- Diagnostics list
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        opts = {},
        keys = {
            { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "All diagnostics" },
            { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "This file's diagnostics" },
        },
    },

    -- Floating terminal: Ctrl+\
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        keys = { { [[<C-\>]], desc = "Terminal" } },
        opts = {
            open_mapping = [[<C-\>]],
            direction = "float",
            float_opts = { border = "rounded" },
        },
    },
}
