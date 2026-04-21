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

-- Spell checking (off by default, toggle manually with <leader>ss)
-- Neovim will download missing spell files automatically on first use.
-- Built-in navigation keymaps (active when spell is on):
--   ]s      → next misspelled word
--   [s      → previous misspelled word
--   z=      → suggest corrections for word under cursor
--   zg      → add word under cursor to your personal dictionary
--   zw      → mark word under cursor as wrong (add to bad-word list)
vim.opt.spell = false
vim.opt.spelllang = { 'en_gb' }  -- active language; changed by <leader>sl

-- Ordered list of languages to cycle through with <leader>sl
local spell_langs = { 'en_gb', 'es', 'fr' }
local spell_lang_idx = 1  -- tracks current position in the list above

-- <leader>ss — toggle spell check on/off
-- Notifies current state and active language so you always know where you are.
vim.keymap.set('n', '<leader>ss', function()
    vim.opt.spell = not vim.opt.spell:get()
    vim.notify('Spell ' .. (vim.opt.spell:get() and 'on' or 'off') .. ' [' .. spell_langs[spell_lang_idx] .. ']')
end, { desc = 'Toggle spell check' })

-- <leader>sl — cycle active spell language (en_gb → es → fr → en_gb → ...)
-- Language is changed regardless of whether spell is currently on or off,
-- so you can pre-select a language before toggling spell on.
vim.keymap.set('n', '<leader>sl', function()
    spell_lang_idx = (spell_lang_idx % #spell_langs) + 1
    vim.opt.spelllang = { spell_langs[spell_lang_idx] }
    vim.notify('Spelllang: ' .. spell_langs[spell_lang_idx])
end, { desc = 'Cycle spell language' })
