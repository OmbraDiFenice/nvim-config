local treesitter_utils = require('basicIde.statusBar.lualine_components.treesitter_utils')

---@type LanguageBreadcrumbHandler
return {
	find_breadcrumbs = function(tree_root, starting_node)
		---@type TSNode[]
		local path = {}

		---@type TSNode?
		local last_node = starting_node

		while last_node ~= nil and not last_node:equal(tree_root) do
			local node_type = last_node:type()
			local node_identifier = nil

			if node_type == 'field' then
				node_identifier = treesitter_utils.any_direct_child_of_types(last_node, { 'identifier' })
			elseif node_type == 'function_declaration' then
				node_identifier = treesitter_utils.any_direct_child_of_types(last_node, { 'identifier', 'method_index_expression' })
			elseif node_type == 'function_definition' then
				node_identifier = treesitter_utils.any_direct_child_of_types(last_node, { 'identifier' })
			end

			if node_identifier ~= nil then
				treesitter_utils.add_crumb(path, node_identifier)
			end
			last_node = last_node:parent()
		end

		return table.concat(path, '.')
	end
}
