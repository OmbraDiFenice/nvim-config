local utils = require('basicIde.utils')
local remote_sync_utils = require('basicIde.remote_sync.utils')

---@class QuantConnectStrategySettings
---@field project_id string

local function get_api_token_headers(self)
	local base64 = require('base64')
	local sha = require('basicIde.vendor.sha2')

	local user_id = self.settings.quantconnect_settings.user_id
	local token = self.settings.quantconnect_settings.token
	local timestamp = os.time()

	local timestamped_token = string.format('%s:%s', token, timestamp)
	local hashed_token = sha.sha256(timestamped_token)

	local api_token = base64.encode(string.format('%s:%s', user_id, hashed_token))

	return {
		['Authorization'] = 'Basic ' .. api_token,
		['Timestamp'] = timestamp,
	}
end

local function request(self, method, path, data, headers)
	local curl = require('plenary.curl')
	local json = require('JSON')

	if headers == nil then headers = {} end

	local res = curl.request({
		url = 'https://www.quantconnect.com/api/v2' .. path,
		method = method,
		headers = vim.tbl_extend('force', headers, self:get_api_token_headers()),
		data = data,
	})

	local json_res, err = json:decode(res.body)
	if err ~= nil then
		vim.notify(err, vim.log.levels.ERROR)
	end

	res.json = json_res
	res.json_error = err

	return res
end

local function check_auth(self)
	local res = self:request('GET', '/authenticate')
	vim.notify(res.json, vim.log.levels.INFO)
end

local function get_files(self, project)
	local res = self:request('POST', '/files/read', {
		projectId = project,
	})
	if res.json == nil or res.json.success ~= true then return {} end
	return res.json.files
end

local function get_file(self, project, name)
	local res = self:request('POST', '/files/read', {
		projectId = project,
		name = name,
	})
	if res.json == nil or res.json.success ~= true then return nil end
	return res.json
end

local function create_file(self, project, name, content)
	local urlencode = require('urlencode')

	local res = self:request('POST', '/files/create', {
		projectId = project,
		name = name,
		content = urlencode.encode_url(content),
	})
	if res.json == nil then
		vim.notify('error creating ' .. name, vim.log.levels.ERROR)
	elseif res.json.success ~= true then
		vim.notify(res.json.errors, vim.log.levels.ERROR)
	else
		vim.notify('created ' .. name, vim.log.levels.INFO)
	end
end

local function update_file_content(self, project, name, content)
	local urlencode = require('urlencode')

	local res = self:request('POST', '/files/update', {
		projectId = project,
		name = name,
		content = urlencode.encode_url(content),
	})
	if res.json == nil then
		vim.notify('error updating ' .. name, vim.log.levels.ERROR)
	elseif res.json.success ~= true then
		vim.notify(res.json.errors, vim.log.levels.ERROR)
	else
		vim.notify('updated ' .. name, vim.log.levels.INFO)
	end
end

---@param file_path string
---@param ignore_table table<string, boolean>?
local function synchronize_file(self, file_path, ignore_table)
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
		destination_path = utils.ensure_no_leading_slash(table.concat({ destination_root_path, source_relative_path }, OS.sep))
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
			self:create_file(self.settings.quantconnect_settings.project_id, destination_path, local_content)
			self._remote_cache[destination_path] = self:get_file(self.settings.quantconnect_settings.project_id, destination_path)
			if self.settings.notifications.enabled then vim.notify('done: ' .. file_path .. ' -> ' .. destination_path, vim.log.levels.INFO, { replace = notification}) end
		elseif self._remote_cache[destination_path].content ~= local_content then
			if self.settings.notifications.enabled then notification = vim.notify('remote file changed, updating it', vim.log.levels.INFO, { replace = notification }) end
			self:update_file_content(self.settings.quantconnect_settings.project_id, destination_path, local_content)
			if self.settings.notifications.enabled then vim.notify('done: ' .. file_path .. ' -> ' .. destination_path, vim.log.levels.INFO, { replace = notification}) end
			self._remote_cache[destination_path] = self:get_file(self.settings.quantconnect_settings.project_id, destination_path)
		else
			if self.settings.notifications.enabled then vim.notify('remote file up to date', vim.log.levels.INFO, { replace = notification }) end
			return
		end
	end
	)()
end

local function synchronize_directory(self, dir_path)
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
				if ignore_table[utils.ensure_trailing_slash(file_path)] == true then goto continue end
				_inner(file_path)
			end

			::continue::
		end
	end

	_inner(dir_path)
end

local function init(self)
	local remote_file_data = self:get_files(self.settings.quantconnect_settings.project_id)
	if remote_file_data == nil then return end

	for _, file_data in ipairs(remote_file_data) do
		self._remote_cache[file_data.name] = file_data
	end
end

---@class QuantConnectManager
---@field private settings RemoteSyncSettings
---@field init fun(self: QuantConnectManager)

local QuantConnectManagerMt = {
	init = init,
	check_auth = check_auth,
	get_files = get_files,
	get_file = get_file,
	create_file = create_file,
	update_file_content = update_file_content,
	synchronize_directory = synchronize_directory,
	synchronize_file = synchronize_file,
	request = request,
	get_api_token_headers = get_api_token_headers,
}

---@return QuantConnectManager
local function new(remote_sync_settings)
	local o = {
		settings = remote_sync_settings,
		_timer = nil,
		_remote_cache = {},
	}

	setmetatable(o, QuantConnectManagerMt)
	QuantConnectManagerMt.__index = QuantConnectManagerMt

	return o
end

return {
	new = new,
}
