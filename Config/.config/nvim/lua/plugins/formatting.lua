-- Format on save (falls back to the language server when no formatter is set)
return {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
        { "<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, desc = "Format file" },
    },
    opts = {
        formatters_by_ft = {
            lua        = { "stylua" },
            go         = { "goimports", "gofumpt" },
            python     = { "ruff_format", "ruff_organize_imports" },
            javascript = { "prettier" },
            typescript = { "prettier" },
            javascriptreact = { "prettier" },
            typescriptreact = { "prettier" },
            json       = { "prettier" },
            yaml       = { "prettier" },
            html       = { "prettier" },
            css        = { "prettier" },
            markdown   = { "prettier" },
            sh         = { "shfmt" },
            bash       = { "shfmt" },
            c          = { "clang-format" },
            cpp        = { "clang-format" },
        },
        format_on_save = { timeout_ms = 1500, lsp_format = "fallback" },
    },
}
