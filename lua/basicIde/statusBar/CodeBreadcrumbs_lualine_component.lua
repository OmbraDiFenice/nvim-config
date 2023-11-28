local lualine = require('lualine')
local lualine_highlight = require('lualine.highlight')

---Extract the text from the given `buf` at the given `range`
---@param buf integer # the buffer number to get the text from
---@param range integer[] # range descriptor as returned by |vim.treesitter.get_range()|
---@return string # the text from the buffer at the given range
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

---Extract the treesitter identifier node of a given node.
---Identifier nodes are children nodes of the actual entity they are identifier of in treesitter.
---@param node TSNode
---@return TSNode?
local function get_named_node_identifier(node)
	for i = 0, node:named_child_count(), 1 do
		local child = node:named_child(i)
		if child ~= nil and child:type() == 'identifier' then
			return child
		end
	end
end

---Find the treesitter node path from root of the file to the given `tree_node`
---@param tree_node TSNode
---@return TSNode[]
local function find_breadcrumbs(tree_node)
	---@type TSNode[]
	local path = {}
	local root = tree_node:tree():root()
	---@type TSNode?
	local last_node = tree_node

	while last_node ~= nil and not last_node:equal(root) do
		if Is_in_list(last_node:type(), { 'function_definition', 'class_definition' }) then
			local node_identifier = get_named_node_identifier(last_node)
			if node_identifier ~= nil then
				table.insert(path, 1, node_identifier)
			end
		end
		last_node = last_node:parent()
	end

	return path
end

---Convert an integer into its hex representation of the RGB components
---@param int_color integer
---@return string # a string in the format `#RRGGBB` where the components are in hex
local function int_to_hex_color(int_color)
	local b = string.format('%x', int_color % 0x100)
	int_color = math.floor(int_color / 0x100)
	local g = string.format('%x', int_color % 0x100)
	int_color = math.floor(int_color / 0x100)
	local r = string.format('%x', int_color % 0x100)

	return '#' .. r .. g .. b
end

---Returns the fg color from treesitter highlighting as an integer, or nil if not found
---@param capture_data { capture: string, lang: string }
---@return { fg: integer, bold: boolean }
local function get_treesitter_highlighting_group_info(capture_data)
	local treesitter_highlight_group = '@' .. capture_data.capture
	local treesitter_specific_highlight_group = treesitter_highlight_group .. '.' .. capture_data.lang
	local treesitter_group_info = vim.empty_dict()

	for _, group in ipairs({ treesitter_specific_highlight_group, treesitter_highlight_group }) do
		treesitter_group_info = vim.api.nvim_get_hl(0, {
			name = group,
			create = false,
		})
		if vim.fn.empty(treesitter_group_info) == 0 then break end
	end

	if vim.fn.empty(treesitter_group_info) == 0 then
		return treesitter_group_info
	end
end


---Extract the highlight group from treesitter of `node`.
---The returned string contains the characters escapes necessary to render it with the right style and color when printed.
---@param node TSNode
---@return string
local function find_highlighting_group(node)
	local row, col, _ = node:start()
	local captures = vim.treesitter.get_captures_at_pos(0, row, col)
	if captures == nil or #captures == 0 then return '' end

	local capture_data = captures[#captures] -- apparently the last one in the list is the most specific one

	local treesitter_highlight_group_info = get_treesitter_highlighting_group_info(capture_data)
	if treesitter_highlight_group_info == nil then return '' end

	local treesitter_int_fg_color = treesitter_highlight_group_info.fg

	local fg_hex_color = int_to_hex_color(treesitter_int_fg_color)
	local bg_hex_color = lualine_highlight.get_lualine_hl('lualine_c_inactive')
			.bg -- ensure that the bg color is consistent with lualine. TODO: get the lualine hl_group from some config or dynamically
	local lualine_highlight_group = '@' .. capture_data.capture .. '.' .. capture_data.lang .. '.lualine'

	local gui_options = nil
	if treesitter_highlight_group_info.bold then
		gui_options = 'bold'
	end

	lualine_highlight.highlight(lualine_highlight_group, fg_hex_color, bg_hex_color or 'None', gui_options, '')

	return '%#' .. lualine_highlight_group .. '#'
end

---@class CodeBreadcrumbs
---@field msg string
local CodeBreadcrumbs_lualine_component = {
	msg = '',
}

---Constructor
---@return CodeBreadcrumbs
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

---Builds the breadcrumb string from the `path` treesitter nodes
---@param path TSNode[]|nil
---@return string
local function build_crumbs_string(path)
	if path == nil then return '' end
	local bufnr = vim.api.nvim_get_current_buf()
	local crumbs = Map(path, function(node)
		local node_text = buf_range_get_text(bufnr, vim.treesitter.get_range(node, bufnr))
		local node_highlight = find_highlighting_group(node) or ''
		return node_highlight .. node_text
	end)
	return table.concat(crumbs, '.')
end

---Recompute the value of the `msg` field and trigger `lualine.refresh()`
---@return nil
function CodeBreadcrumbs_lualine_component:update()
	local lang = vim.bo.filetype
	local parsers = vim.treesitter.language.get_filetypes(lang)
	if #parsers == 0 then return end

	local tree_node = vim.treesitter.get_node()
	if tree_node == nil then return end

	local path = find_breadcrumbs(tree_node)
	self.msg = build_crumbs_string(path)
	lualine.refresh()
end

return CodeBreadcrumbs_lualine_component
