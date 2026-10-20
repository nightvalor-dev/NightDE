return {
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            signs = {
                add          = { text = "▎" },
                change       = { text = "▎" },
                delete       = { text = "" },
                topdelete    = { text = "" },
                changedelete = { text = "▎" },
            },
            on_attach = function(buf)
                local gs = require("gitsigns")
                local map = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc }) end
                map("]h", function() gs.nav_hunk("next") end, "Next git change")
                map("[h", function() gs.nav_hunk("prev") end, "Previous git change")
                map("<leader>gp", gs.preview_hunk, "Preview change")
                map("<leader>gr", gs.reset_hunk, "Undo change")
                map("<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
            end,
        },
    },
}
