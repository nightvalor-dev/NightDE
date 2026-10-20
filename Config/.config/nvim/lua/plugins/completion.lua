-- Autocompletion: Enter accepts, Tab / Shift+Tab move, Ctrl+Space opens the menu
return {
    "saghen/blink.cmp",
    version = "1.*",                       -- prebuilt fuzzy matcher, no Rust needed
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
        keymap = {
            preset = "enter",
            ["<Tab>"]   = { "select_next", "snippet_forward", "fallback" },
            ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        },
        appearance = { nerd_font_variant = "mono" },
        completion = {
            menu = { border = "rounded" },
            documentation = { auto_show = true, auto_show_delay_ms = 300, window = { border = "rounded" } },
            list = { selection = { preselect = true, auto_insert = false } },
        },
        signature = { enabled = true, window = { border = "rounded" } },
        sources = { default = { "lsp", "path", "snippets", "buffer" } },
    },
}
