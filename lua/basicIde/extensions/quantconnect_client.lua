---@class RemoteFileData
---@field name string
---@field content string

---@class QuantConnectStrategySettings
---@field project_id string

---@class QuantConnectClient
---@field settings RemoteSyncSettings
---@field new function(self: QuantConnectClient, remote_sync_settings: RemoteSyncSettings): QuantConnectClient
---@field check_auth function(self: QuantConnectClient): nil
---@field get_files function(self: QuantConnectClient, project_id: string): RemoteFileData[]
---@field get_file function(self: QuantConnectClient, project_id: string, name: string): RemoteFileData
---@field create_file function(self: QuantConnectClient, project_id: string, name: string, content: string): nil
---@field update_file_content function(self: QuantConnectClient, project_id: string, name: string, content: string): nil
---@field compile_project function(self: QuantConnectClient, project_id: string): string?
---@field run_backtest function(self: QuantConnectClient, project_id: string): nil

local QuantConnectClient = {}

---Constructor
---@param remote_sync_settings RemoteSyncSettings
---@return QuantConnectClient
function QuantConnectClient:new(remote_sync_settings)
	local o = {
		settings = remote_sync_settings,
		_timer = nil,
		_remote_cache = {},
	}

	setmetatable(o, self)
	self.__index = self

	return o
end

---Build a valid QuantConnectApi token and returns the headers to add to
---the request to make it valid
---@return {Authorization: string, Timestamp: number}
function QuantConnectClient:_get_api_token_headers()
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

---Send a synchronous API request to QuantConnect
---@param method 'GET'|'POST'
---@param path string the path of the QusantConnect endpoint for the request, including the leading / and without the host part
---@param data table? the data to send. Only used in POST requests
---@param headers table<string, string>?
---@return {status: number, json: any, json_error: any}
function QuantConnectClient:_request(method, path, data, headers)
	local curl = require('plenary.curl')
	local json = require('JSON')

	if headers == nil then headers = {} end

	local res = curl.request({
		url = 'https://www.quantconnect.com/api/v2' .. path,
		method = method,
		headers = vim.tbl_extend('force', headers, self:_get_api_token_headers()),
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

---Run a request to QuantConnect to check if the authentication is successful
function QuantConnectClient:check_auth()
	local res = self:_request('GET', '/authenticate')
	vim.notify(res.json, vim.log.levels.INFO)
end

---Get the list of files from the given project
---@param project string
---@return RemoteFileData[]
function QuantConnectClient:get_files(project)
	local res = self:_request('POST', '/files/read', {
		projectId = project,
	})
	if res.json == nil or res.json.success ~= true then return {} end
	return res.json.files
end

---Get a single file from the given project
---@param project string
---@param name string path of the file to get relative to the remote project root
---@return RemoteFileData
function QuantConnectClient:get_file(project, name)
	local res = self:_request('POST', '/files/read', {
		projectId = project,
		name = name,
	})
	if res.json == nil or res.json.success ~= true then return nil end
	return res.json
end

---Create a new file in the given project
---@param project string
---@param name string path of the file to create relative to the remote project root
---@param content string the content of the file to create
function QuantConnectClient:create_file(project, name, content)
	local urlencode = require('urlencode')

	local res = self:_request('POST', '/files/create', {
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

---Update the content of the given file
---@param project string
---@param name string path of the file to update relative to the remote project root
---@param content string new content of the file
function QuantConnectClient:update_file_content(project, name, content)
	local urlencode = require('urlencode')

	local res = self:_request('POST', '/files/update', {
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

---Synchronously compile the remote compilation of the given project.
---After triggering the compilation, this function will poll the server until the compilation is finished.
---If the compilation is not finished in 6 seconds, it is considered failed.
---@param project string
---@return string? compileId if the compilation succeedes it returns the compile ID that can be used in later requests, otherwise it returns nil
function QuantConnectClient:compile_project(project)
	local notif = vim.notify('compiling project', vim.log.levels.INFO)

	local res = self:_request('POST', '/compile/create', {
		projectId = project,
	})
	if res.status ~= 200 or res.json == nil then
		vim.notify('error triggering project compilation', vim.log.levels.ERROR, { replace = notif })
		return
	elseif res.json.success ~= true then
		vim.notify(res.json.errors, vim.log.levels.ERROR, { replace = notif })
		return
	end

	local compile_id = res.json.compileId
	vim.wait(6000, function()
		res = self:_request('POST', '/compile/read', {
			projectId = project,
			compileId = compile_id,
		})
		return res.status == 200 and res.json ~= nil and res.json.state ~= 'InQueue'
	end, 2000)

	if res.status ~= 200 or res.json == nil then
		vim.notify('error getting compilation status', vim.log.levels.ERROR, { replace = notif })
		return
	end
	if res.json.state == 'BuildError' then
		vim.notify(res.json.errors, vim.log.levels.ERROR, { replace = notif })
		return
	end

	local msg = 'compilation completed'
	if res.json.logs ~= nil then msg = res.json.logs end
	vim.notify(msg, vim.log.levels.INFO, { replace = notif })
	return res.json.compileId
end

---Trigger a remote backtest for the given project.
---As first step it triggers a compilation by calling `run_backtest`. If that compilation fails it stops there.
---This function only starts the backtest, it will not wait for it to finish. Check on the project website to get the status
---@param project string
function QuantConnectClient:run_backtest(project)
	local compile_id = self:compile_project(project)
	if compile_id == nil then return end

	local notif = vim.notify('running backtest', vim.log.levels.INFO)

	local res = self:_request('POST', '/backtests/create', {
		projectId = project,
		compileId = compile_id,
		backtestName = 'backtest',
	})
	if res.status ~= 200 or res.json == nil then
		vim.notify('error running backtest', vim.log.levels.ERROR, { replace = notif })
		return
	elseif res.json.success ~= true then
		vim.notify(res.json.errors, vim.log.levels.ERROR, { replace = notif })
		return
	end

	vim.notify('backtest status: ' .. res.json.backtest.status, vim.log.levels.INFO, { replace = notif })
end

return QuantConnectClient
