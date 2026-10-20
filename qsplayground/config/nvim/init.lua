-- before we begin, LINE NUMBERS!
vim.wo.number = true

-- disable netrw for file explorer
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- moving to packer instead of plug for native lua support, ensure packer is installed
local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath("data").."/site/pack/packer/start/packer.nvim"
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({"git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path})
        vim.cmd("packadd packer.nvim")
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

require("packer").startup(function(use)
    use "wbthomason/packer.nvim" -- Packer manages itself

    -- lsp support
    use "neovim/nvim-lspconfig"
    use "williamboman/mason.nvim"
    use "williamboman/mason-lspconfig.nvim"

    -- tree-sitter for better syntax highlighting and parsing
    use "nvim-treesitter/nvim-treesitter"
 
    -- autocompletion
    use "hrsh7th/nvim-cmp"
    use "hrsh7th/cmp-buffer"
    use "hrsh7th/cmp-path"
    use "saadparwaiz1/cmp_luasnip"
    use "hrsh7th/cmp-nvim-lsp"
    use "hrsh7th/cmp-nvim-lua"

    -- snippets
    use "L3MON4D3/LuaSnip"
    use "rafamadriz/friendly-snippets"

    -- nvim-tree and dependencies
    use "kyazdani42/nvim-web-devicons" -- optional icons
    use "nvim-tree/nvim-tree.lua"

    -- additional plugins
    use { "codota/tabnine-nvim", run = "./dl_binaries.sh" }
    use "xiyaowong/transparent.nvim"

    if packer_bootstrap then
        require("packer").sync()
    end

    -- setup Mason and ensure servers are installed
require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = { "lua_ls", "gopls", "clangd", "ts_ls", "marksman" },
    automatic_installation = true,
})

-- setup nvim-lspconfig
local lspconfig = require("lspconfig")

-- capabilities for autocompletion
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- attach keymaps when LSP is attached to a buffer
local on_attach = function(client, bufnr)
    local opts = { noremap = true, silent = true, buffer = bufnr }

    -- keymaps for LSP (prime goated thx)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>f", function()
        vim.lsp.buf.format { async = true }
    end, opts)
end



-- individual language servers
local servers = { "lua_ls", "gopls", "clangd", "ts_ls", "marksman" }
for _, server in ipairs(servers) do
    lspconfig[server].setup({
        capabilities = capabilities,
        on_attach = on_attach,
    })
end

end)

-- Setup nvim-tree
require("nvim-tree").setup({
    view = {
        width = 30,
        side = "left",
    },
    renderer = {
        group_empty = true,
    },
    filters = {
        dotfiles = false,
    },
})


