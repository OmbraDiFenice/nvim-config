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
		settings.mappings[i][1] = utils.ensure_trailing_slash(mapping[1])
		settings.mappings[i][2] = utils.ensure_trailing_slash(mapping[2])
	end
end

---@class RsyncManager
---@field private settings RemoteSyncSettings
---@field _timer userdata?
local RsyncManager = {}

---Constructor
---@param remote_sync_settings RemoteSyncSettings
---@return RsyncManager
function RsyncManager:new(remote_sync_settings)
	clean_settings(remote_sync_settings)
	local o = {
		settings = remote_sync_settings,
		_timer = nil,
	}

	setmetatable(o, self)
	self.__index = self

	return o
end

---Starts the master ssh connection to reduce latency on subsequent synchronizations.
---The master socket is created in the project session folder.
---@return nil
function RsyncManager:start_master_ssh()
	self.ssh_control_master_socket = vim.fn.tempname()
	if self.ssh_control_master_socket == nil then vim.notify("unable to create ssh control master socket, remote sync will be slower", vim.log.levels.WARN) return end

	self.master_job_id = utils.runAndReturnOutput({
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
	if self._timer ~= nil then self._timer:stop() end

	local source_relative_path, destination_root_path = remote_sync_utils.map_file_path(self.settings.mappings, file_path)
	if source_relative_path == nil or destination_root_path == nil then
		vim.notify('unable to map ' .. file_path .. ' to a remote directory.', vim.log.levels.ERROR)
		return
	end

	local function build_ignore_list()
		local temp_filename = vim.fn.tempname()
		if temp_filename == nil then vim.notify('Unable to create temp file, skipping ignored files on sync', vim.log.levels.WARN) return end

		local temp_file_handle = io.open(temp_filename, 'w')
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

		return temp_filename
	end

	local exclude_list_filename = build_ignore_list()
	local exclude_from_option = ''
	if exclude_list_filename ~= nil then
		exclude_from_option = '--exclude-from=' .. exclude_list_filename
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
		exclude_from_option,
		source_relative_path,
		self.settings.rsync_settings.remote_user .. '@' .. self.settings.rsync_settings.remote_host .. ':' .. destination_root_path
	}

	self._timer = utils.debounce({ timer = self._timer }, function()
		local notification
		if self.settings.notifications.enabled then notification = vim.notify('sync started: '..source_relative_path, vim.log.levels.INFO, { on_close = function() notification = nil end }) end
		utils.runAndReturnOutput(command, vim.schedule_wrap(function(output, exit_code)
			if exit_code ~= 0 then
				vim.notify(output, vim.log.levels.ERROR, { replace = notification })
			end
			if self.settings.notifications.enabled then vim.notify('sync completed', vim.log.levels.INFO, { replace = notification }) end
			if exclude_list_filename ~= nil then
				os.remove(exclude_list_filename)
			end
		end), { clear_env = false })
	end)
end

---Send an entire directory (recursively) to the remote server
---@param dir_path string
---@return nil
function RsyncManager:synchronize_directory(dir_path)
	if vim.fn.isdirectory(dir_path) == 1 then
		dir_path = utils.ensure_trailing_slash(dir_path)
	end

	self:synchronize_file(dir_path)
end

return RsyncManager
