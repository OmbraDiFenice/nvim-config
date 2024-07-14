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

			if Is_in_list(node_type, { 'type_definition', 'struct_specifier' }) then
				node_identifier = treesitter_utils.any_direct_child_of_types(last_node, { 'type_identifier' })
			elseif node_type == 'function_definition' then
				local function_declarator_node = treesitter_utils.first_deep_child_of_types(last_node, { 'function_declarator' })
				if function_declarator_node ~= nil then
					node_identifier = treesitter_utils.any_direct_child_of_types(function_declarator_node, { 'identifier' })
				end
			end

			if node_identifier ~= nil then
				treesitter_utils.add_crumb(path, node_identifier)
			end
			last_node = last_node:parent()
		end

		return table.concat(path, '.')
	end
}
