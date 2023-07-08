local api = require('nvim-tree.api')
local Event = api.events.Event

M = {
	state_filename = '.nvim-tree.state',
	state = {
		cursor_position = { 1, 0 },
		expanded_folders = {},
	},
}

local state_setting_callbacks = {
	cursor_position = require('basicIde/folderViewExtensions/cursorPosition'),
	expanded_folders = require('basicIde/folderViewExtensions/expandedFolders'),
}

local load_state_from_file = function(file_name)
	local state_file = io.open(file_name, 'r')
	if state_file == nil then
		print('no state file found')
		return
	end

	local state = {}

	for line in state_file:lines() do
		print('checking line ' .. line)
		for key, value in string.gmatch(line, '([%w_]+)=(.+)') do
			print('found key = ' .. key .. ' and value = ' .. value)

			local callbacks = state_setting_callbacks[key]
			if callbacks then
				state[key] = callbacks.deserialize(tostring(value))
			else
				print('found unknown config "' .. key .. '" in state file, ignoring')
			end
		end
	end

	state_file:close()

	return state
end

M.load = function ()
	M.state = load_state_from_file(M.state_filename)
end

M.store = function ()
	local state_file = io.open(M.state_filename, 'w')
	if state_file == nil then
		print('file open failed')
		return
	end

	for key, value in pairs(M.state) do
		local callbacks = state_setting_callbacks[key]
		if callbacks then
			local serialized_value = callbacks.serialize(value)
			state_file:write(key .. '=' .. serialized_value .. '\n')
		end
	end

	state_file:flush()
	state_file:close()
end

M.update = function ()
	for key, callbacks in pairs(state_setting_callbacks) do
		local value = callbacks.get()
		M.state[key] = value
	end
end

M.setup = function()
	M.load()

	for key, callbacks in pairs(state_setting_callbacks) do
		callbacks.setup(M.state[key])
	end

	vim.api.nvim_create_autocmd('VimLeave', {
		callback = function()
			M.update()
			M.store()
			return true
		end
	})
end

return M
