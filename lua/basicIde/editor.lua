return {
	use_deps = function(use)
		use {
			'Pocco81/auto-save.nvim',
		}
	end,

	configure = function()
		require('auto-save').setup()

		vim.keymap.set('n', '<leader>Q', function() vim.cmd('qall') end, { desc = 'close window' })

		-- opens help windows on the right, taken from https://vi.stackexchange.com/questions/4452/how-can-i-make-vim-open-help-in-a-vertical-split
		local vimrc_help_group = vim.api.nvim_create_augroup('vimrc_help', { clear = true })
		vim.api.nvim_create_autocmd( { 'BufEnter' }, {
			desc = 'Move opened help windows to the right',
			group = vimrc_help_group,
			pattern = '*.txt',
			callback = function (args)
				if vim.api.nvim_buf_get_option(args.buf, 'buftype') == 'help' then
					vim.cmd 'wincmd L'
				end
			end
		})
	end
}
