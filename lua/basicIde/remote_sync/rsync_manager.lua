local utils = require('basicIde.utils')

---Make sure that the settings are well formatted
---@param project_settings RemoteSyncSettings
---@return nil # it cleans the settings in place
local function clean_settings(project_settings)
	for i, mapping in ipairs(project_settings.mappings) do
		project_settings.mappings[i][1] = utils.ensure_trailing_slash(mapping[1])
		project_settings.mappings[i][2] = utils.ensure_trailing_slash(mapping[2])
	end
end

---Convert a local absolute path to the pair [local relative path, remote absolute path]
---@param mappings string[][] # the path mappings from |RemoteSyncSettings|
---@param file_path string # local absolute path to be mapped
---@return string|nil, string|nil # local relative path, remtoe absolute path. Both nil if it wasn't possible to map the input
local function map_file_path(mappings, file_path)
	local selected_prefix = ''
	local source_relative_path = nil
	local destination_root_path = nil

	for _, mapping in ipairs(mappings) do
		local local_prefix = mapping[1]
		local remote_prefix = mapping[2]

		if file_path:find(local_prefix, 1, true) == 1 and #selected_prefix < #local_prefix then
			source_relative_path = utils.ensure_no_leading_slash(string.sub(file_path, #local_prefix))
			destination_root_path = remote_prefix
			selected_prefix = local_prefix
		end
	end

	return source_relative_path, destination_root_path
end

---@class RsyncManager
---@field private settings RemoteSyncSettings
local RsyncManager = {}

---Constructor
---@param remote_sync_settings RemoteSyncSettings
---@return RsyncManager
function RsyncManager:new(remote_sync_settings)
	clean_settings(remote_sync_settings)
	local o = {
		settings = remote_sync_settings,
	}

	setmetatable(o, self)
	self.__index = self

	return o
end

---Starts the master ssh connection to reduce latency on subsequent synchronizations.
---The master socket is created in the project session folder.
---@return nil
function RsyncManager:start_master_ssh()
	self.ssh_control_master_socket = Get_data_directory() .. '/ssh_control_master'
	self.master_job_id = utils.runAndReturnOutput({
		'ssh',
		'-o', 'ControlMaster=yes',
		'-o', 'ControlPath=' .. self.ssh_control_master_socket,
		'-N',
		self.settings.remote_user .. '@' .. self.settings.remote_host,
	}, function(output, exit_code)
		if exit_code ~= 0 then
			Printlines(output)
		end
	end, { clear_env = false })
end

---Send a single file to the remote server
---@param file_path string
---@return nil
function RsyncManager:synchronize_file(file_path)
	if self.settings.mappings == nil then return end

	local source_relative_path, destination_root_path = map_file_path(self.settings.mappings, file_path)
	if source_relative_path == nil or destination_root_path == nil then
		LogWarning('unable to map ' .. file_path .. ' to  a remote directory.')
		return
	end

	local command = {
		'rsync',
		'-e', 'ssh -l ' .. self.settings.remote_user .. ' -S ' .. self.ssh_control_master_socket,
		'--executability', -- preserve executability
		'--times',       -- preserve timestamps
		'--compress',
		'--relative',
		'--recursive',
		source_relative_path,
		self.settings.remote_user .. '@' .. self.settings.remote_host .. ':' .. destination_root_path
	}
	utils.runAndReturnOutput(command, function(output, exit_code)
		if exit_code ~= 0 then
			Printlines(output)
		end
	end, { clear_env = false })
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
