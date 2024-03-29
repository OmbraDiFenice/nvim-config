function _G.set_terminal_keymaps()
	local opts = { buffer = 0 }
	vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
	vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
	--   vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
	--   vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
	vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
end

---@type IdeModule
return {
	use_deps = function(use)
		use 'akinsho/toggleterm.nvim'
	end,

	configure = function(project_settings)
		require('toggleterm').setup({
			open_mapping = [[<c-\>]],
			direction = 'vertical',
			size = function() return vim.o.columns * 0.4 end,
			clear_env = false,
			on_create = function(terminal)
				local init_environment_cmd = project_settings.terminal.init_environment_cmd

				if not init_environment_cmd then return end

				terminal:send(init_environment_cmd, false)
			end
		})

		vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
	end,
}
