local ts_utils = require('basicIde.statusBar.lualine_components.treesitter_utils')

---Return the name of the key of the json object represented by node
---@param node TSNode treesitter node of type 'pair'
---@return string?
local function get_object_key(node)
		local key_node = unpack(node:field("key"))
		local key_text_node = ts_utils.any_direct_child_of_types(key_node, {'string_content'})
		if key_text_node ~= nil then
			return ts_utils.colorize_text(ts_utils.get_node_text(key_text_node), key_text_node)
		end
end

---Return the node of the array element
---@param current_node TSNode treesitter node of type 'pair'
---@param starting_node TSNode node where the cursor is
---@return string
local function get_array_element(starting_node, current_node)
	for i, ith_element_node in ipairs(current_node:named_children()) do
		if ith_element_node ~= nil and ts_utils.is_parent(ith_element_node, starting_node) then
			return ts_utils.colorize_text(string.format('[%s]', i-1), ith_element_node)
		end
	end
	return ts_utils.colorize_text('[]', current_node)
end

---@type LanguageBreadcrumbHandler
return {
	-- some reference taken from https://github.com/phelipetls/jsonpath.nvim/blob/main/lua/jsonpath.lua
	find_breadcrumbs = function(tree_root, starting_node)
		local path = ""

		---@type TSNode?
		local last_node = starting_node

		while last_node ~= nil and not last_node:equal(tree_root) do
			local crumb = nil
			local node_type = last_node:type()

			if node_type == 'pair' then
				crumb = get_object_key(last_node)
				path = '.' .. crumb .. path
			elseif node_type == 'array' then
				crumb = get_array_element(starting_node, last_node)
				path = crumb .. path
			end

			last_node = last_node:parent()
		end

		return path
	end,
}
