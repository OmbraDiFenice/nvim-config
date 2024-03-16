---@type IdeModule
return {
	use_deps = function(use)
		use {
			'rcarriga/nvim-notify',
		}

		use {
			'mrded/nvim-lsp-notify',
		}
	end,

	configure = function(project_settings)
		local telescope = require('telescope')
		telescope.load_extension('notify')

		local notify = require('notify')
		notify.setup({
			timeout = 1500,
			top_down = false,
			render = 'wrapped-compact',
		})

		vim.notify = notify
		vim.keymap.set('n', '<leader>sn', telescope.extensions.notify.notify, { desc = "Search in notifications" })

		if project_settings.lsp.notifications.enabled then
			require('lsp-notify').setup({})
		end
	end
}
