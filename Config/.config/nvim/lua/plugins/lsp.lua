-- Language servers: installed automatically by Mason, configured with Neovim 0.11's vim.lsp.config
local servers = {
    "gopls",          -- Go
    "pyright",        -- Python
    "lua_ls",         -- Lua (this config)
    "ts_ls",          -- JavaScript / TypeScript
    "bashls",         -- Shell scripts
    "jsonls",         -- JSON
    "yamlls",         -- YAML
    "clangd",         -- C / C++
    "html",
    "cssls",
}

return {
    { "mason-org/mason.nvim", cmd = "Mason", opts = { ui = { border = "rounded" } } },

    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "mason-org/mason.nvim",
            "mason-org/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            "saghen/blink.cmp",
        },
        config = function()
            -- Completion capabilities for every server
            vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

            -- Per-server settings
            vim.lsp.config("lua_ls", {
                settings = {
                    Lua = {
                        diagnostics = { globals = { "vim", "hl" } },   -- hl = Hyprland Lua config
                        workspace = { checkThirdParty = false },
                        telemetry = { enable = false },
                    },
                },
            })
            vim.lsp.config("gopls", {
                settings = {
                    gopls = {
                        gofumpt = true,
                        staticcheck = true,
                        usePlaceholders = true,
                        analyses = { unusedparams = true, shadow = true },
                    },
                },
            })

            require("mason").setup({ ui = { border = "rounded" } })
            require("mason-lspconfig").setup({
                ensure_installed = servers,
                automatic_enable = true,
            })
            -- Formatters / linters used by conform.nvim
            require("mason-tool-installer").setup({
                ensure_installed = { "stylua", "goimports", "gofumpt", "prettier", "ruff", "shfmt", "clang-format" },
            })

            -- Keys that only exist when a language server is attached
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("nightde-lsp", { clear = true }),
                callback = function(ev)
                    local map = function(lhs, rhs, desc)
                        vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
                    end
                    local tb = require("telescope.builtin")
                    map("gd", tb.lsp_definitions,       "Go to definition")
                    map("gr", tb.lsp_references,        "References")
                    map("gI", tb.lsp_implementations,   "Go to implementation")
                    map("gy", tb.lsp_type_definitions,  "Go to type")
                    map("gD", vim.lsp.buf.declaration,  "Go to declaration")
                    map("K", function() vim.lsp.buf.hover({ border = "rounded" }) end, "Hover docs")
                    map("<leader>cr", vim.lsp.buf.rename,       "Rename symbol")
                    map("<leader>ca", vim.lsp.buf.code_action,  "Code action")
                    map("<leader>cs", tb.lsp_document_symbols,  "Symbols in file")
                    map("<leader>ch", function()
                        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
                    end, "Toggle inlay hints")
                end,
            })
        end,
    },
}
