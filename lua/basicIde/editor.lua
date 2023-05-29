return {
	use_deps = function(use)
		use {
			'Pocco81/auto-save.nvim',
		}
	end,

	configure = function()
		require('auto-save').setup()

		vim.keymap.set('n', '<leader>Q', function() vim.cmd('qall') end, { desc = 'close window' })
	end
}
