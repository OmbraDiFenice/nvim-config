local rsync_manager = require('basicIde.remote_sync.rsync_manager')

---@type IdeModule
return {
	use_deps = function(use)
	end,

	configure = function(project_settings)
		if not project_settings.remote_sync.enabled then return end

		local manager = rsync_manager:new(project_settings.remote_sync)
		manager:start_master_ssh()

		if project_settings.remote_sync.sync_on_save then
			vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
				desc = 'Synchronize the saved buffer on the remote machine',
				callback = function(args)
					manager:synchronize_file(args.file)
				end,
			})
		end

		local augroup = vim.api.nvim_create_augroup('BasicIde.RemoteSync', {})

		vim.api.nvim_create_autocmd('User', {
			group = augroup,
			pattern = 'SyncFile',
			callback = function(args)
				if args.data.path == nil then return end
				manager:synchronize_file(args.data.path)
			end
		})

		vim.api.nvim_create_autocmd('User', {
			group = augroup,
			pattern = 'SyncDir',
			callback = function(args)
				if args.data.path == nil then return end
				manager:synchronize_directory(args.data.path)
			end
		})
	end
}
