local utils = require('basicIde.utils')
local remote_sync_utils = require('basicIde.remote_sync.utils')

---@class RsyncStrategySettings
---@field remote_user string
---@field remote_host string

---Make sure that the settings are well formatted
---@param settings RemoteSyncSettings
---@return nil # it cleans the settings in place
local function clean_settings(settings)
	for i, mapping in ipairs(settings.mappings) do
		settings.mappings[i][1] = utils.paths.ensure_trailing_slash(mapping[1])
		settings.mappings[i][2] = utils.paths.ensure_trailing_slash(mapping[2])
	end
end

---@class RsyncManager
---@field private settings RemoteSyncSettings
---@field _timers table<string, userdata> timers to control debouncing per-file
---@field _exclude_list_filename string path to the exclude file
local RsyncManager = {}

---Constructor
---@param remote_sync_settings RemoteSyncSettings
---@return RsyncManager
function RsyncManager:new(remote_sync_settings)
	clean_settings(remote_sync_settings)
	local o = {
		settings = remote_sync_settings,
		_timers = {},
		_exclude_list_filename = table.concat({utils.get_data_directory(), "rsync_exclude_list"}, utils.files.OS.sep),
	}

	setmetatable(o, self)
	self.__index = self

	o:_build_ignore_list()

	vim.api.nvim_create_autocmd('User', {
		pattern = 'ProjectSettingsChanged',
		desc = 'recreate rsync ignore list file on project settings change',
		callback = function()
			o:_build_ignore_list()
		end,
	})

	return o
end

function RsyncManager:_build_ignore_list()
	if utils.files.is_file(self._exclude_list_filename) then
		os.remove(self._exclude_list_filename)
	end

	local temp_file_handle = io.open(self._exclude_list_filename, 'w')
	if temp_file_handle == nil then
		vim.notify('Unable to open temp file, skipping ignored files on sync', vim.log.levels.WARN)
		return
	end

	local ignore_list = remote_sync_utils.build_ignore_list(self.settings.exclude_paths, self.settings.exclude_git_ignored_files)

	for _, exclude in ipairs(ignore_list) do
		temp_file_handle:write(exclude .. '\n')
	end

	temp_file_handle:flush()
	temp_file_handle:close()
end

---Starts the master ssh connection to reduce latency on subsequent synchronizations.
---The master socket is created in the project session folder.
---@return nil
function RsyncManager:start_master_ssh()
	self.ssh_control_master_socket = vim.fn.tempname()
	if self.ssh_control_master_socket == nil then vim.notify("unable to create ssh control master socket, remote sync will be slower", vim.log.levels.WARN) return end

	self.master_job_id = utils.proc.runAndReturnOutput({
		'ssh',
		'-o', 'ControlMaster=yes',
		'-o', 'ControlPath=' .. self.ssh_control_master_socket,
		'-N',
		self.settings.rsync_settings.remote_user .. '@' .. self.settings.rsync_settings.remote_host,
	}, function(output, exit_code)
		if exit_code ~= 0 then
			vim.notify(output, vim.log.levels.ERROR)
		end
	end, { clear_env = false })
end

---Send a single file to the remote server
---@param file_path string
---@return nil
function RsyncManager:synchronize_file(file_path)
	if self.settings.mappings == nil then return end

	local source_root_path, source_relative_path, destination_root_path = remote_sync_utils.map_file_path(self.settings.mappings, file_path)
	if source_root_path == nil or source_relative_path == nil or destination_root_path == nil then
		vim.notify('unable to map ' .. file_path .. ' to a remote directory.', vim.log.levels.ERROR)
		return
	end

	local master_socket_option = ''
	if self.ssh_control_master_socket ~= nil then
		master_socket_option = 'ssh -l ' .. self.settings.rsync_settings.remote_user .. ' -S ' .. self.ssh_control_master_socket
	end

	local command = {
		'rsync',
		'-e',
		master_socket_option,
		'--executability', -- preserve executability
		'--times',       -- preserve timestamps
		'--compress',
		'--relative',
		'--recursive',
		'--delete',
		'--links',
		'--safe-links',
		'--exclude-from=' .. self._exclude_list_filename,
		source_relative_path,
		self.settings.rsync_settings.remote_user .. '@' .. self.settings.rsync_settings.remote_host .. ':' .. destination_root_path
	}

	local timer_key = source_root_path .. '#' .. source_relative_path .. '#' .. destination_root_path
	self._timers[timer_key] = utils.debounce({ timer = self._timers[timer_key] }, function()
		---@type string?
		local notif_text = table.concat({utils.paths.ensure_no_trailing_slash(source_root_path), source_relative_path}, utils.files.OS.sep) .. " -> " .. destination_root_path
		vim.api.nvim_exec_autocmds('User', {
			group = 'BasicIde.RemoteSync',
			pattern = 'SyncStart',
			data = { text = notif_text }
		})
		utils.proc.runAndReturnOutput(command, vim.schedule_wrap(function(output, exit_code)
			local log_level = vim.log.levels.INFO
			notif_text = nil
			if exit_code ~= 0 then
				notif_text = table.concat(output, utils.files.OS.sep)
				log_level = vim.log.levels.ERROR
			end
			vim.api.nvim_exec_autocmds('User', {
				group = 'BasicIde.RemoteSync',
				pattern = 'SyncEnd',
				data = { log_level = log_level, text = notif_text }
			})
		end), { clear_env = false, cwd = source_root_path })
	end)
end

---Send an entire directory (recursively) to the remote server
---@param dir_path string
---@return nil
function RsyncManager:synchronize_directory(dir_path)
	if utils.files.is_dir(dir_path) then
		dir_path = utils.paths.ensure_trailing_slash(dir_path)
	end

	self:synchronize_file(dir_path)
end

return RsyncManager
