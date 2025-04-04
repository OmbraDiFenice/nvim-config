local utils = require('basicIde.utils')
local rsync_manager = require('basicIde.remote_sync.rsync_manager')
local quantconnect_manager = require('basicIde.remote_sync.quantconnect')
local fs_monitor = vim.loop.new_fs_event()
local git_monitor = vim.loop.new_fs_event()

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
	local manager = nil
	if project_settings.remote_sync.strategy == 'rsync' then
		manager = rsync_manager:new(project_settings.remote_sync)
		manager:start_master_ssh()
	elseif project_settings.remote_sync.strategy == 'quantconnect' then
		manager = quantconnect_manager:new(project_settings.remote_sync)
		manager:init()
	end

	return manager
end

---Setup file watcher to trigger repository sync on git worktree changes (checkout, stash etc)
---@param project_root_path string
---@param project_settings ProjectSettings
local function setup_sync_on_git_changes(project_root_path, project_settings)
	if git_monitor == nil then vim.notify('unable to create watch event for git sync on changes. Files won\'t be synchronized automatically on checkouts'); return end

	local git_dir_lines, err = utils.proc.runAndReturnOutputSync('git rev-parse --path-format=absolute --git-dir')
	if err ~= 0 then vim.notify('unable to find git dir. Files won\'t be synchronized automatically'); return end
	local git_dir = table.concat(git_dir_lines, "") -- rev-parse returns multiple lines but some of them are empty and the order is inconsistent

	local git_common_dir_lines = utils.proc.runAndReturnOutputSync('git rev-parse --path-format=absolute --git-common-dir')
	local git_common_dir = table.concat(git_common_dir_lines, "") -- rev-parse returns multiple lines but some of them are empty and the order is inconsistent

	local in_git_worktree = git_common_dir ~= git_dir
	local git_head_path = table.concat({ git_dir, 'HEAD' }, utils.files.OS.sep)

	local function start_monitoring()
		git_monitor:start(git_head_path,
			{ watch_entry = true },
			function(err, _, events)
				if err ~= nil then vim.notify(err, vim.log.levels.ERROR); return end
				git_monitor:stop()
				start_monitoring()
				if events.change == nil then return end
				vim.schedule_wrap(function()
					vim.api.nvim_exec_autocmds('User', {
						group = 'BasicIde.RemoteSync',
						pattern = 'SyncDir',
						data = {
							path = project_root_path,
						},
					})
					if in_git_worktree then
						vim.api.nvim_exec_autocmds('User', {
							group = 'BasicIde.RemoteSync',
							pattern = 'SyncDir',
							data = {
								path = git_common_dir,
							},
						})
					end
				end)()
		end)
	end

	start_monitoring()
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

		vim.keymap.set('n', '<leader>rs', sync_current_file, { desc = 'Synch current file to the remote machine' })

		local project_root_path = vim.fn.getcwd(-1, -1)
		if project_settings.remote_sync.sync_on_git_head_change and utils.files.path_exists(table.concat({ project_root_path, ".git" }, utils.files.OS.sep)) then
			setup_sync_on_git_changes(project_root_path, project_settings)
		end
	end
}
