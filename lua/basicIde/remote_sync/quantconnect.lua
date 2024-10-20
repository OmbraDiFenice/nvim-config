local utils = require('basicIde.utils')
local remote_sync_utils = require('basicIde.remote_sync.utils')
local QuantconnectClient  = require('basicIde.extensions.quantconnect_client')

---@class QuantConnectManager
---@field new function(self: QuantConnectManager, remote_sync_settings: RemoteSyncSettings): QuantConnectManager
---@field settings RemoteSyncSettings
---@field _client QuantConnectClient
---@field _timer userdata?
---@field _remote_cache table<string, FileData>
---@field init function(self: QuantConnectManager)
---@field synchronize_file function(self: QuantConnectManager, file_path: string, ignore_table: table<string, boolean>?)
---@field synchronize_directory function(self: QuantConnectManager, dir_path: string)

---@type QuantConnectManager
local QuantConnectManager = {}

---@param file_path string
---@param ignore_table table<string, boolean>?
function QuantConnectManager:synchronize_file(file_path, ignore_table)
	if self.settings.mappings == nil then return end
	if self._timer ~= nil then self._timer:stop() end

	if ignore_table == nil then
		local ignore_list = remote_sync_utils.build_ignore_list(self.settings.exclude_paths, self.settings.exclude_git_ignored_files)
		ignore_table = remote_sync_utils.build_ignore_table(ignore_list)
	end

	if ignore_table[file_path] == true then return end

	local source_relative_path, destination_root_path = remote_sync_utils.map_file_path(self.settings.mappings, file_path)
	if source_relative_path == nil or destination_root_path == nil then
		vim.notify('unable to map ' .. file_path .. ' to a remote directory.', vim.log.levels.ERROR)
		return
	end

	if source_relative_path:sub(1, 2) == '.' .. OS.sep then
		source_relative_path = source_relative_path:sub(3)
	end

	local destination_path = destination_root_path
	if source_relative_path ~= '' then
		destination_path = utils.paths.ensure_no_leading_slash(table.concat({ destination_root_path, source_relative_path }, OS.sep))
	end

	vim.schedule_wrap(function()
		local notification
		if self.settings.notifications.enabled then
			notification = vim.notify(
				'sync started: ' .. file_path .. ' -> ' .. destination_path,
				vim.log.levels.INFO,
				{ on_close = function() notification = nil end }
			)
		end

		local local_content = Load_file(file_path)
		if self._remote_cache[destination_path] == nil then
			if self.settings.notifications.enabled then notification = vim.notify('remote file not found, creating it', vim.log.levels.INFO, { replace = notification }) end
			self._client:create_file(self.settings.quantconnect_settings.project_id, destination_path, local_content)
			self._client:get_file(self.settings.quantconnect_settings.project_id, destination_path, function(file_content) self._remote_cache[destination_path] = file_content end)
			if self.settings.notifications.enabled then vim.notify('done: ' .. file_path .. ' -> ' .. destination_path, vim.log.levels.INFO, { replace = notification}) end
		elseif self._remote_cache[destination_path].content ~= local_content then
			if self.settings.notifications.enabled then notification = vim.notify('remote file changed, updating it', vim.log.levels.INFO, { replace = notification }) end
			self._client:update_file_content(self.settings.quantconnect_settings.project_id, destination_path, local_content)
			if self.settings.notifications.enabled then vim.notify('done: ' .. file_path .. ' -> ' .. destination_path, vim.log.levels.INFO, { replace = notification}) end
			self._client:get_file(self.settings.quantconnect_settings.project_id, destination_path, function(file_content) self._remote_cache[destination_path] = file_content end)
		else
			if self.settings.notifications.enabled then vim.notify('remote file up to date', vim.log.levels.INFO, { replace = notification }) end
			return
		end
	end
	)()
end

function QuantConnectManager:synchronize_directory(dir_path)
	local lfs = require('lfs')

	if not vim.fn.isdirectory(dir_path) == 1 then return end

	local ignore_list = remote_sync_utils.build_ignore_list(self.settings.exclude_paths, self.settings.exclude_git_ignored_files)
	local ignore_table = remote_sync_utils.build_ignore_table(ignore_list)

	-- This function is there only to avoid recomputing the ignore list on each recursive call
	local function _inner(dir_path)
		for file in lfs.dir(dir_path) do
			if file == '.' or file == '..' then goto continue end

			local file_path = table.concat({ dir_path, file }, OS.sep)
			local file_mode = lfs.attributes(file_path, 'mode')

			if file_mode == 'file' then
				if ignore_table[file_path] == true then goto continue end
				self:synchronize_file(file_path, ignore_table)
			elseif file_mode == 'directory' then
				if ignore_table[utils.paths.ensure_trailing_slash(file_path)] == true then goto continue end
				_inner(file_path)
			end

			::continue::
		end
	end

	_inner(dir_path)
end

function QuantConnectManager:init()
	self._client:get_files(self.settings.quantconnect_settings.project_id, function(remote_file_data)
		if remote_file_data == nil then return end

		for _, file_data in ipairs(remote_file_data) do
			self._remote_cache[file_data.name] = file_data
		end
	end)
end

---@return QuantConnectManager
function QuantConnectManager:new(remote_sync_settings)
	local o = {
		settings = remote_sync_settings,
		_client = QuantconnectClient:new(remote_sync_settings),
		_timer = nil,
		_remote_cache = {},
	}

	setmetatable(o, self)
	self.__index = self

	return o
end

return QuantConnectManager
