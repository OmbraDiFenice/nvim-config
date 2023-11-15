local rsync_manager = require('basicIde.remote_sync.rsync_manager')

return {
	use_deps = function(use)
	end,

	configure = function(project_settings)
		if not project_settings.remote_sync.enabled then return end

		local manager = rsync_manager:new(project_settings.remote_sync)
		manager:start_master_ssh()

		vim.api.nvim_create_autocmd({'BufWritePost'}, {
			desc = 'Synchronize the saved buffer on the remote machine',
			callback = function (args)
				manager:synchronize_file(args.file)
			end,
		})
	end
}
