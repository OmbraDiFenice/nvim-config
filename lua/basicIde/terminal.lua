function _G.set_terminal_keymaps()
  local opts = {buffer = 0}
  vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
  vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
--   vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
--   vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
end

return {
	use_deps = function(use)
		use 'akinsho/toggleterm.nvim'
	end,

	configure = function()
		require('toggleterm').setup({
			open_mapping = [[<c-\>]],
		})

	vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
	end,
}
