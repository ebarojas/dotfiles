-- Clipboard via OSC 52 (works over SSH with Ghostty)

if vim.env.SSH_CONNECTION then
  vim.g.clipboard = "osc52"
  vim.opt.clipboard = ""
else
  vim.opt.clipboard = "unnamedplus"
end

-- LSP keymaps
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'gl', vim.diagnostic.open_float)
