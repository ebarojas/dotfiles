require('mason').setup()
require('mason-lspconfig').setup{
    ensure_installed = {
        'pyright',
        'solargraph',
        'ts_ls',
        'vue_ls',
        'bashls',
        'texlab',
        'marksman',
    },
}

require('blink.cmp').setup()

-- Apply blink.cmp capabilities to all LSP servers
vim.lsp.config('*', {
    capabilities = require('blink.cmp').get_lsp_capabilities(),
})
