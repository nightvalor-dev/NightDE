local au = vim.api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup("nightde", { clear = true })

-- Briefly highlight yanked text
au("TextYankPost", {
    group = group,
    callback = function() vim.hl.on_yank({ timeout = 180 }) end,
})

-- Reopen files where you left off
au("BufReadPost", {
    group = group,
    callback = function(ev)
        local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
        local lines = vim.api.nvim_buf_line_count(ev.buf)
        if mark[1] > 0 and mark[1] <= lines then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- Go, Makefiles: real tabs. Web/Lua/YAML: 2 spaces
au("FileType", {
    group = group,
    pattern = { "go", "make" },
    callback = function() vim.opt_local.expandtab = false end,
})
au("FileType", {
    group = group,
    pattern = { "lua", "javascript", "typescript", "javascriptreact", "typescriptreact",
                "json", "jsonc", "yaml", "html", "css", "scss" },
    callback = function()
        vim.opt_local.shiftwidth = 2
        vim.opt_local.tabstop = 2
        vim.opt_local.softtabstop = 2
    end,
})

-- Equalise splits when the terminal window is resized
au("VimResized", { group = group, command = "tabdo wincmd =" })

-- Close helper windows with q
au("FileType", {
    group = group,
    pattern = { "help", "qf", "checkhealth", "lspinfo", "man" },
    callback = function(ev)
        vim.bo[ev.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
    end,
})
