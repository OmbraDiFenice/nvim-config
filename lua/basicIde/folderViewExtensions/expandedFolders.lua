local api = require('nvim-tree.api')
local core = require('nvim-tree.core')
local utils = require('nvim-tree.utils')
local lib = require('nvim-tree.lib')
local Event = api.events.Event

local M = {}

M.get = function()
	local expanded_folders = {}

	local function findOpenFolders(root_nodes)
		for _, node_data in pairs(root_nodes) do
			if node_data.type == "directory" and node_data.open then
				table.insert(expanded_folders, node_data.absolute_path)
				findOpenFolders(node_data.nodes)
			end
		end
	end

	local nodes = core.get_explorer().nodes
	findOpenFolders(nodes)

	return expanded_folders
end

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

M.apply = function(expanded_folders)
	local function get_expanded_nodes()
		return utils.get_nodes_by_line(core.get_explorer().nodes, core.get_nodes_starting_line())
	end

	local expanded_nodes = get_expanded_nodes()

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

M.deserialize = function(raw_value)
	local deserialized = {}

	for path in string.gmatch(raw_value, '[^,]+') do
		table.insert(deserialized, path)
	end

	return deserialized
end

return M
