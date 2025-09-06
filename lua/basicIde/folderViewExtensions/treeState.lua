local utils = require('basicIde.utils')

---@class TreeState
---@field cursor_position TreeStateCursorPosition
---@field expanded_folders string[]

---@class TreeStateManager
---@field state_filename string
---@field state TreeState
local M = {
	state_filename = utils.get_data_directory() .. '/nvim-tree.state',
	state = {
		cursor_position = { 1, 0 },
		expanded_folders = {},
	},
}

local state_setting_modules = {
	cursor_position = require('basicIde/folderViewExtensions/cursorPosition'),
	expanded_folders = require('basicIde/folderViewExtensions/expandedFolders'),
}

---@param file_name string
---@return TreeState
local load_state_from_file = function(file_name)
	local state = utils.tables.deepcopy(M.state)

	local state_file = io.open(file_name, 'r')
	if state_file == nil then
		vim.notify('no state file found')
		return state
	end

	for line in state_file:lines() do
		for key, value in string.gmatch(line, '([%w_]+)=(.+)') do
			local module = state_setting_modules[key]
			if module then
				state[key] = module.deserialize(tostring(value))
			else
				vim.notify('found unknown config "' .. key .. '" in state file, ignoring')
			end
		end
	end

	state_file:close()

	return state
end

---Load |TreeState| from file.
---Read the state file and delegates the deserialization of the data related to each field of |TreeState| to the corresponding module.
---@return nil
M.load = function()
	M.state = load_state_from_file(M.state_filename)
end

---Serializes |TreeState| in the state file.
---Delegates the serialization to the modules handling each field of |TreeState|
---@return nil
M.store = function()
	local state_file = io.open(M.state_filename, 'w')
	if state_file == nil then
		vim.notify('file open failed', vim.log.levels.ERROR)
		return
	end

	for key, value in pairs(M.state) do
		local module = state_setting_modules[key]
		if module then
			local serialized_value = module.serialize(value)
			state_file:write(key .. '=' .. serialized_value .. '\n')
		end
	end

	state_file:flush()
	state_file:close()
end

---Recompute the values of |TreeState|.
---Delegates the computation to each module
---@return nil
M.update = function()
	for key, module in pairs(state_setting_modules) do
		local value = module.get()
		M.state[key] = value
	end
end

---Initialize the component.
---Load the state from file, initializing each modules, and make sure to store the updated state to file before quitting
---@return nil
M.setup = function()
	M.load()

	for key, module in pairs(state_setting_modules) do
		module.setup(M.state[key])
	end

	vim.api.nvim_create_autocmd('VimLeave', {
		callback = function()
			if utils.tables.is_table_empty(vim.api.nvim_list_uis()) then return end
			M.update()
			M.store()
			return true
		end
	})
end

return M
