local api = require('nvim-tree.api')
local core = require('nvim-tree.core')
local utils = require('nvim-tree.utils')
local view = require('nvim-tree.view')
local Event = api.events.Event

---@alias TreeStateExpandedFolders string[]

---@class ExpandedFoldersModule
local M = {
	_expanded_folders = {},
	_tree_was_opened_at_least_once = false,
}

---Get the current expanded folders internal state
---@return TreeStateExpandedFolders
M.get = function()
	return M._expanded_folders
end

---Update the current expanded folders internal state
M.update_expanded_folders = function()
	if not M._tree_was_opened_at_least_once then return end

	local explorer = core.get_explorer()
	if explorer == nil then return end -- could be nil if running in headless mode

	local expanded_folders = {}

	---Recursively find all the open folders in the tree view.
	---Puts the result in `expanded_folders`, coming from the closure.
	---@param root_nodes Node[] # list of root nodes to start the search from
	local function findOpenFolders(root_nodes)
		for _, node_data in pairs(root_nodes) do
			if node_data.type == "directory" then
				---@cast node_data DirectoryNode
				if node_data.open then
					table.insert(expanded_folders, node_data.absolute_path)
					findOpenFolders(node_data.nodes)
				end
			end
		end
	end

	findOpenFolders(explorer.nodes)

	M._expanded_folders = expanded_folders
end

---Initialize the module
---@param expanded_folders TreeStateExpandedFolders
---@return nil
M.setup = function(expanded_folders)
	M._expanded_folders = expanded_folders
	local bufnr = view.get_bufnr();

	-- Apparently Event.Ready is only triggered when the plugin starts the first time
	-- and then the internal "expanded" status is kept during the session
	api.events.subscribe(Event.Ready, function()
		M.apply(M._expanded_folders)
		M._tree_was_opened_at_least_once = true
	end)

	vim.api.nvim_create_autocmd('BufWinLeave', {
		buffer = bufnr,
		callback = function()
			M.update_expanded_folders()
		end,
	})
end

---Applies the current state to the tree view, expanding all the folders that should be expanded
---@param expanded_folders TreeStateExpandedFolders
---@return nil
M.apply = function(expanded_folders)
	---Returns the top level nodes not yet expanded
	---@return table<integer, Node> nodes indexed by line
	local function get_expanded_nodes()
		return utils.get_nodes_by_line(core.get_explorer().nodes, core.get_nodes_starting_line())
	end

	local expanded_nodes = get_expanded_nodes()

	---@param path string
	---@return DirectoryNode? # the tree node corresponding to the `path` if that path matches with the next top level nodes not yet expanded, nil otherwise
	local function should_expand(path)
		for _, node in pairs(expanded_nodes) do
			if node.type == "directory" and path == node.absolute_path then
				---@cast node DirectoryNode
				return node
			end
		end
		return nil
	end

	for _, path in pairs(expanded_folders) do
		local node = should_expand(path)
		if node ~= nil then
			node:expand_or_collapse()
			expanded_nodes = get_expanded_nodes()
		end
	end
end

---@param expanded_folders TreeStateExpandedFolders
---@return string
M.serialize = function(expanded_folders)
	local serialized = ''

	for _, path in pairs(expanded_folders) do
		if #serialized == 0 then
			serialized = path
		else
			serialized = serialized .. ',' .. path
		end
	end

	return serialized
end

---@param raw_value string
---@return TreeStateExpandedFolders
M.deserialize = function(raw_value)
	local deserialized = {}

	for path in string.gmatch(raw_value, '[^,]+') do
		table.insert(deserialized, path)
	end

	return deserialized
end

return M
