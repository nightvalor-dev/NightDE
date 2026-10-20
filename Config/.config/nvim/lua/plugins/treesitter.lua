-- Syntax highlighting / indentation via Tree-sitter.
-- Uses the nvim-treesitter "main" branch, the one that supports Neovim 0.12.
-- Parsers compile on your machine: needs tree-sitter-cli, gcc, curl and tar.
local ensure_installed = {
    "bash", "c", "css", "diff", "dockerfile", "go", "gomod", "gosum", "html",
    "javascript", "json", "lua", "luadoc", "markdown", "markdown_inline", "python",
    "query", "regex", "rust", "sql", "toml", "tsx", "typescript", "vim", "vimdoc", "yaml",
}

return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,                 -- this branch does not support lazy-loading
    build = ":TSUpdate",
    config = function()
        local ts = require("nvim-treesitter")
        ts.setup()
        ts.install(ensure_installed)          -- no-op for parsers already installed

        local available = {}
        for _, lang in ipairs(ts.get_available()) do available[lang] = true end

        -- Turn on highlighting + indentation for every file type that has a parser,
        -- installing the parser the first time you open such a file.
        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("nightde-treesitter", { clear = true }),
            callback = function(ev)
                local lang = vim.treesitter.language.get_lang(ev.match)
                if not lang or not available[lang] then return end

                local function start()
                    if not vim.api.nvim_buf_is_valid(ev.buf) then return end
                    if pcall(vim.treesitter.start, ev.buf, lang) then
                        vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end

                -- Parser already usable (installed, or bundled with Neovim)?
                local ok, loaded = pcall(vim.treesitter.language.add, lang)
                if ok and loaded then
                    start()
                else
                    ts.install({ lang }):await(function() vim.schedule(start) end)
                end
            end,
        })
    end,
}
