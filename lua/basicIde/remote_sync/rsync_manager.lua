local utils = require('basicIde.utils')

local function clean_settings(project_settings)
	for i, mapping in ipairs(project_settings.mappings) do
		project_settings.mappings[i][1] = utils.ensure_trailing_slash(mapping[1])
		project_settings.mappings[i][2] = utils.ensure_trailing_slash(mapping[2])
	end
end

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

local RsyncManager = {}

function RsyncManager:new(remote_sync_settings)
	clean_settings(remote_sync_settings)
	local o = {
		settings = remote_sync_settings,
	}

	setmetatable(o, self)
	self.__index = self

	return o
end

function RsyncManager:start_master_ssh()
	self.ssh_control_master_socket = Get_data_directory() .. 'ssh_control_master'
	self.master_job_id = utils.runAndReturnOutput({
		'ssh',
		'-o', 'ControlMaster=yes',
		'-o', 'ControlPath=' .. self.ssh_control_master_socket,
		'-N',
		self.settings.remote_user .. '@' .. self.settings.remote_host,
	}, P, { clear_env = false })
end

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
		'--times', -- preserve timestamps
		'--compress',
		'--relative',
		source_relative_path,
		self.settings.remote_user .. '@' .. self.settings.remote_host .. ':' .. destination_root_path
	}
	utils.runAndReturnOutput(command, P, { clear_env = false })
end

return RsyncManager
