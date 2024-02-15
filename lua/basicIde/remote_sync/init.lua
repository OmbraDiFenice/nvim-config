local rsync_manager = require('basicIde.remote_sync.rsync_manager')

local function sync_current_file()
	local path = vim.api.nvim_buf_get_name(0)
	vim.api.nvim_exec_autocmds('User', {
		group = 'BasicIde.RemoteSync',
		pattern = 'SyncFile',
		data = {
			path = path,
		},
	})
end

---@type IdeModule
return {
	use_deps = function(use)
	end,

	configure = function(project_settings)
		-- the group needs to exist even if the feature is disabled so that other code can still subscribe to that group events without errors
		local augroup = vim.api.nvim_create_augroup('BasicIde.RemoteSync', {})

		if not project_settings.remote_sync.enabled then return end

		local manager = rsync_manager:new(project_settings.remote_sync)
		manager:start_master_ssh()

		if project_settings.remote_sync.sync_on_save then
			vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
				group = augroup,
				desc = 'Synchronize the saved buffer on the remote machine',
				callback = function(args)
					manager:synchronize_file(args.file)
				end,
			})
		end

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

		vim.keymap.set('n', '<leader>rs', sync_current_file, { desc = 'Send the current file to the remote machine' })
	end
}
