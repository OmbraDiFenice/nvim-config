local utils = require('basicIde.utils')
local treesitter_utils = require('basicIde.statusBar.lualine_components.treesitter_utils')

---@type LanguageBreadcrumbHandler
return {
	find_breadcrumbs = function(tree_root, starting_node)
		---@type string[]
		local path = {}

		---@type TSNode?
		local last_node = starting_node

		while last_node ~= nil and not last_node:equal(tree_root) do
			local node_type = last_node:type()
			if utils.tables.is_in_list(node_type, { 'function_definition', 'class_definition' }) then
				local node_identifier = treesitter_utils.any_direct_child_of_types(last_node, { 'identifier' })
				if node_identifier ~= nil then
					treesitter_utils.add_crumb(path, node_identifier)
				end
			end
			last_node = last_node:parent()
		end

		return table.concat(path, '.')
	end
}
