---@type IdeModule
return {
	use_deps = function(use)
		use 'navarasu/onedark.nvim'
	end,

	configure = function()
		-- vim.o.termguicolors = true
		local plugin = require('onedark')
		plugin.setup {
			style = 'dark',
		}
		plugin.load()
	end,
}
