return {
	use_deps = function(use)
		use {
			'Pocco81/auto-save.nvim',
		}
	end,

	configure = function()
		require('auto-save').setup()
	end
}
