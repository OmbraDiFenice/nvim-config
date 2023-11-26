local api = require('nvim-tree.api')
local core = require('nvim-tree.core')
local utils = require('nvim-tree.utils')
local lib = require('nvim-tree.lib')
local Event = api.events.Event

---@alias TreeStateExpandedFolders string[]

---@class TreeNode
---@field type string
---@field open boolean
---@field absolute_path string
---@field nodes TreeNode[]

---@class ExpandedFoldersModule
local M = {}

---Get the current expanded folders internal state
---@return TreeStateExpandedFolders
M.get = function()
	---@type TreeStateExpandedFolders
	local expanded_folders = {}

	---Recursively find all the open folders in the tree view.
	---Puts the result in `expanded_folders`, coming from the closure.
	---@param root_nodes TreeNode[] # list of root nodes to start the search from
	local function findOpenFolders(root_nodes)
		for _, node_data in pairs(root_nodes) do
			if node_data.type == "directory" and node_data.open then
				table.insert(expanded_folders, node_data.absolute_path)
				findOpenFolders(node_data.nodes)
			end
		end
	end

	local nodes = core.get_explorer().nodes
	---@cast nodes TreeNode[]
	findOpenFolders(nodes)

	return expanded_folders
end

---Initialize the module
---@param expanded_folders TreeStateExpandedFolders
---@return nil
M.setup = function(expanded_folders)
	-- Apparently Event.Ready is only triggered when the plugin starts the first time
	-- and then the internal "expanded" status is kept.
	--
	-- If that wasn't the case we would need to recompute expanded_folders and keep a
	-- temporary "last value" similarly to what it's done for cursorPosition
	api.events.subscribe(Event.Ready, function()
		M.apply(expanded_folders)
	end)
end

---Applies the current state to the tree view, expanding all the folders that should be expanded
---@param expanded_folders TreeStateExpandedFolders
---@return nil
M.apply = function(expanded_folders)
	---Returns the top level nodes not yet expanded
	---@return TreeNode[]
	local function get_expanded_nodes()
		return utils.get_nodes_by_line(core.get_explorer().nodes, core.get_nodes_starting_line())
	end

	local expanded_nodes = get_expanded_nodes()

	---@param path string
	---@return TreeNode? # the tree node corresponding to the `path` if that path matches with the next top level nodes not yet expanded, nil otherwise
	local function should_expand(path)
		for _, node in pairs(expanded_nodes) do
			if path == node.absolute_path then
				return node
			end
		end
		return nil
	end

	for _, path in pairs(expanded_folders) do
		local node = should_expand(path)
		if node ~= nil then
			lib.expand_or_collapse(node)
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
