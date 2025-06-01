function _G.setup_terminal()
	local opts = { buffer = 0 }

	-- keymaps
	vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
	vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
	--   vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
	--   vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
	vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
	vim.keymap.set('t', '<C-w>', function()
		local term_index = vim.api.nvim_buf_get_var(0, 'toggle_number')
		local terminal = require('toggleterm.terminal').get(term_index)
		if terminal == nil then return end

		local direction = 'float'
		if terminal.direction == 'float' then
			direction = 'vertical'
		end

		local mode = vim.api.nvim_get_mode()['mode']
		if mode == 't' or mode == 'i' then mode = 'i' end

		terminal:close()
		terminal:change_direction(direction)
		terminal:open()
		if mode == 'i' then
			vim.api.nvim_set_current_win(terminal.window)
			vim.api.nvim_feedkeys(mode, 'n', true)
		end
	end, opts)

	-- layout
	vim.api.nvim_set_option_value('signcolumn', 'no', { win = vim.api.nvim_get_current_win() })
	vim.api.nvim_set_option_value('foldcolumn', '0', { win = vim.api.nvim_get_current_win() })
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

		vim.cmd('autocmd! TermOpen term://* lua setup_terminal()')
	end,
}
