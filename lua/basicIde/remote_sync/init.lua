local rsync_manager = require('basicIde.remote_sync.rsync_manager')
local fs_monitor = vim.loop.new_fs_event()

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
		else
			local cwd = vim.fn.getcwd(-1, -1)
			if fs_monitor ~= nil and cwd ~= nil then
				fs_monitor:start(cwd, { watch_entry = true, stat = false, recursive = true }, vim.schedule_wrap(function (err, filepath, events)
					-- if string.sub(filepath, #filepath) == '~' then return end
					local full_path = cwd .. OS.sep .. filepath
					if File_exists(full_path) then
						manager:synchronize_file(full_path)
					end
				end))
			end
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
