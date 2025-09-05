local show_report = require('basicIde.loader.show_report')

-- to create a floating window the UI must be completely started.
-- Use VimEnter event to ensure to run the code after that.
-- The callback is wrapped in vim.schedule() to ensure that it is
-- executed after any other callback listening for VimEnter event
-- has finished. This is useful in case the nvim-tree plugin is working
-- and the editor.tree_view.open_on_enter basicIde option is set to true,
-- otherwise the split view the plugin creates will be screwed up.
vim.api.nvim_create_autocmd('VimEnter', {
	callback=function()
		vim.schedule(function()
			show_report()
		end)
	end
})
