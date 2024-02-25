local lualine_highlight = require('lualine.highlight')

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
---@return { fg: integer, bold: boolean }?
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

---Extract the text from the given `buf` for the given node at the given `range`
---@param buf integer # the buffer number to get the text from
---@param node TSNode # node for which to get the text
---@return string # the text from the buffer associated to the given node
local function buf_range_get_text(buf, node)
	local Range = require('vim.treesitter._range')
	local range = vim.treesitter.get_range(node, buf)
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

return {
	---Extract the treesitter identifier node of a given node.
	---Identifier nodes are children nodes of the actual entity they are identifier of in treesitter.
	---@param node TSNode
	---@param node_identifier_types string[] # use any of these node types to extract the identifier of `node`
	---@return TSNode?
	any_direct_child_of_types = function(node, node_identifier_types)
		for i = 0, node:named_child_count(), 1 do
			local child = node:named_child(i)
			if child ~= nil and Is_in_list(child:type(), node_identifier_types) then
				return child
			end
		end
	end,

	---@param node TSNode
	---@return TSNode?
	json_key = function(node)
		local key_node = node:named_child(0)
		if key_node ~= nil then
			return key_node:child(1)
		end
	end,

	---@param start_node TSNode
	---@param max_parent_node TSNode
	first_parent_child_of = function(start_node, max_parent_node)
		while start_node:parent() ~= nil and not start_node:parent():equal(max_parent_node) do
			start_node = start_node:parent()
		end
		return start_node
	end,

	---Prepend a new string element to the `path` array with the text from `text_from` node and highlight color taken from `color_from` node
	---WARNING: this function mutates `path`.
	---@param path string[] the string to prepend the new element to
	---@param text_from TSNode treesitter node defining the text to prepend
	---@param color_from TSNode? treesitter node from which to take the highlight color to apply to the prepended text. If not specified use `text_from`
	add_crumb = function(path, text_from, color_from)
		if color_from == nil then color_from = text_from end

		local node_text = buf_range_get_text(vim.api.nvim_get_current_buf(), text_from)
		local node_highlight = find_highlighting_group(color_from) or ''
		table.insert(path, 1, node_highlight .. node_text)
	end
}
