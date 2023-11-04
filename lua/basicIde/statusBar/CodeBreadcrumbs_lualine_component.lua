local function buf_range_get_text(buf, range)
	local Range = require('vim.treesitter._range')
	local start_row, start_col, end_row, end_col = Range.unpack4(range)
	if end_col == 0 then
		if start_row == end_row then
			start_col = -1
			start_row = start_row - 1
		end
		end_col = -1
		end_row = end_row - 1
	end
	local lines = vim.api.nvim_buf_get_text(buf, start_row, start_col, end_row, end_col, {})
	return table.concat(lines, '\n')
end

local function get_named_node_identifier(node, bufnr)
	for i = 0, node:named_child_count(), 1 do
		local child = node:named_child(i)
		if child ~= nil and child:type() == 'identifier' then
			return buf_range_get_text(bufnr, vim.treesitter.get_range(child, bufnr))
		end
	end
end

local function find_breadcrumbs()
	local parsers = vim.treesitter.language.get_filetypes(vim.bo.filetype)
	if #parsers == 0 then return end
	local tree_node = vim.treesitter.get_node()
	if tree_node == nil then return end

	local path = {}

	local bufnr = vim.api.nvim_get_current_buf()
	local root = tree_node:tree():root()

	while tree_node ~= nil and not tree_node:equal(root) do
		if Is_in_list(tree_node:type(), { 'function_definition', 'class_definition' }) then
			local node_identifier = get_named_node_identifier(tree_node, bufnr)
			if node_identifier ~= nil then
				table.insert(path, 1, node_identifier)
			end
		end
		tree_node = tree_node:parent()
	end

	return path
end

local CodeBreadcrumbs_lualine_component = {
	msg = '',
}

function CodeBreadcrumbs_lualine_component:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self

	vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
		desc = 'Update code breadcrumbs statusline info',
		callback = function() self:update() end,
	})

	return o
end

function CodeBreadcrumbs_lualine_component:update()
	local path = find_breadcrumbs()
	if path ~= nil then
		self.msg = table.concat(path, '.')
		require('lualine').refresh()
	end
end

return CodeBreadcrumbs_lualine_component
