local utils = require('basicIde.utils')
local rsync_manager = require('basicIde.remote_sync.rsync_manager')
local quantconnect_manager = require('basicIde.remote_sync.quantconnect')
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

---@param project_settings ProjectSettings
local function get_manager(project_settings)
	local _, git_exit_code = utils.proc.runAndReturnOutputSync('git rev-parse --git-dir')
	local is_in_git_repo = git_exit_code == 0
	local manager = nil
	if project_settings.remote_sync.strategy == 'rsync' then
		manager = rsync_manager:new(project_settings.remote_sync, is_in_git_repo)
		manager:start_master_ssh()
	elseif project_settings.remote_sync.strategy == 'quantconnect' then
		manager = quantconnect_manager:new(project_settings.remote_sync, is_in_git_repo)
		manager:init()
	end

	return manager
end

---@type IdeModule
return {
	use_deps = function(use, _, use_rocks)
		use 'nvim-lua/plenary.nvim'
		use_rocks { 'json-lua', 'urlencode' }
	end,

	configure = function(project_settings)
		-- the group needs to exist even if the feature is disabled so that other code can still subscribe to that group events without errors
		local augroup = vim.api.nvim_create_augroup('BasicIde.RemoteSync', {})

		if not project_settings.remote_sync.enabled then return end

		local manager = get_manager(project_settings)
		if manager == nil then
			vim.notify('unsupported remote sync strategy: ' .. project_settings.remote_sync.strategy, vim.log.levels.ERROR)
			return
		end

		if project_settings.remote_sync.sync_on_save then
			vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
				group = augroup,
				desc = 'Synchronize the saved buffer on the remote machine',
				callback = function(args)
					manager:synchronize_file(args.file)
				end,
			})
		else
			if fs_monitor ~= nil then
				fs_monitor:start(project_settings.PROJECT_ROOT_DIRECTORY, { watch_entry = true, stat = false, recursive = true }, vim.schedule_wrap(function (err, filepath, events)
					-- if string.sub(filepath, #filepath) == '~' then return end
					local full_path = table.concat({ project_settings.PROJECT_ROOT_DIRECTORY, filepath }, utils.files.OS.sep)
					if utils.files.path_exists(full_path) then
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

		local notification
		vim.api.nvim_create_autocmd('User', {
			desc = 'Show notification when remote sync is started',
			group = augroup,
			pattern = 'SyncStart',
			-- @param args { data: { text: string?, log_level: int? } }
			callback = function(args)
				local force_notification = args.data.log_level ~= nil and args.data.log_level > vim.log.levels.INFO
				if project_settings.remote_sync.notifications.enabled or force_notification then
					local notif_text = "sync start"
					if args.data.text ~= nil then notif_text = notif_text .. ": " .. args.data.text end
					notification = vim.notify(notif_text, args.data.log_level, { on_close = function() notification = nil end })
				end
			end
		})

		vim.api.nvim_create_autocmd('User', {
			desc = 'Show notification when remote sync is completed',
			group = augroup,
			pattern = 'SyncEnd',
			-- @param args { data: { text: string?, log_level: int? } }
			callback = function(args)
				local force_notification = args.data.log_level ~= nil and args.data.log_level > vim.log.levels.INFO
				if project_settings.remote_sync.notifications.enabled or force_notification then
					local notif_text = "sync done"
					if args.data.text ~= nil then notif_text = notif_text .. ": " .. args.data.text end
					vim.notify(notif_text, args.data.log_level, { replace = notification })
				end
			end
		})

		vim.keymap.set('n', '<leader>rs', sync_current_file, { desc = 'Synch current file to the remote machine' })

		if project_settings.remote_sync.sync_on_git_head_change then
			vim.api.nvim_create_autocmd('User', {
				group = 'BasicIde.GitMonitor',
				pattern = 'HeadChange',
				callback = function(args)
					if args.data.paths == nil or #args.data.paths == 0 then return end
					for _, path in ipairs(args.data.paths) do
						if utils.files.is_file(path) then
							manager:synchronize_file(args.data.path)
						elseif utils.files.is_dir(path) then
							manager:synchronize_directory(path)
						end
					end
				end
			})
		end
	end
}
