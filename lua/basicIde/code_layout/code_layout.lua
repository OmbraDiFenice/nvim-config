local utils = require('basicIde.utils')
local tsutils = require('basicIde.statusBar.lualine_components.treesitter_utils')

---@class CodeLayout
---@field update fun()
---@field close_code_layout_window fun()
---@field navigate_to_source fun()
---@field get_buf fun(): integer

---@class HighlightingInfo
---@field hl_group string
---@field row integer
---@field col_start integer
---@field col_end integer

local M = {}

---@param node TSNode
---@param types string[]
---@return integer the depth of the input node in its tree only counting the node types provided in input
local function find_depth(node, types)
	local depth = 0
	local n = node:parent()

	while n ~= nil and not n:equal(node:tree():root()) do
		if utils.tables.is_in_list(n:type(), types) then
			depth = depth + 1
		end
		n = n:parent()
	end

	return depth
end

---@param node TSNode
---@param types string[]
---@return TSNode?
local function first_parent_of_type(node, types)
	local root = node:tree():root()
	---@type TSNode?
	local n = node
	while n ~= nil and not n:equal(root) do
		if utils.tables.is_in_list(n:type(), types) then return n end
		n = n:parent()
	end
end

---@alias CodeLayoutMapping table<integer, TSNode> the table key is the line in the code layout buffer corresponding to the mapped TS node in the source buffer

---@param bufnr integer
---@param filetype string
---@param query_str string
---@return CodeLayoutMapping
local function getMapping(bufnr, filetype, query_str)
	local parser = vim.treesitter.get_parser(bufnr)
	local trees = parser:parse()
	local tree = trees[1]

	---@type CodeLayoutMapping
	local nodes = {}

	local query = vim.treesitter.query.parse(filetype, query_str)
	for id, node, _ in query:iter_captures(tree:root(), 0) do
		local capture_name = query.captures[id]
		if capture_name == 'result' then
			table.insert(nodes, node)
		end
	end

	return nodes
end

---@param hl_groups HighlightingInfo[]
---@param scratch_buf integer
local function apply_highlighting(hl_groups, scratch_buf)
	local ns = vim.api.nvim_create_namespace('scratch_highlighting')
	for _, data in ipairs(hl_groups) do
		vim.api.nvim_buf_add_highlight(scratch_buf, ns, data.hl_group, data.row, data.col_start, data.col_end)
	end
end

---@param node TSNode
---@param buf integer
---@return string
local function find_highlighting_group(node, buf)
	local row1, col1, _, _ = node:range()
	local treesitter_info = vim.inspect_pos(buf, row1, col1).treesitter
	local treesitter_hl = ''
	if #treesitter_info ~= 0 then
		treesitter_hl = treesitter_info[#treesitter_info].hl_group
	end
	return treesitter_hl
end

---@param nodes CodeLayoutMapping
---@param node_types string[] treesitter node types to be considered when computing the node depth in the code layout
---@param source_buf integer
---@param scratch_buf integer
---@param scratch_win integer
---@param stop_at_list TokenPattern[]
---@param ignore_list TokenPattern[]
---@param indent_width integer
local function populateCodeLayoutBuffer(nodes, node_types, source_buf, scratch_buf, scratch_win, stop_at_list, ignore_list, indent_width)
	---@param node TSNode
	---@param token_patterns TokenPattern[]
	---@return boolean
	local function node_in_token_list(node, token_patterns)
		local node_type = node:type()
		local node_text = tsutils.get_node_text(node, source_buf)
		for _, token_pattern in ipairs(token_patterns) do
			if (token_pattern.type == 'node_type' and token_pattern.value == node_type) or (token_pattern.type == 'token' and node_text == token_pattern.value) then
				return true
			end
		end
		return false
	end

	---Reconstruct the text corresponding to the "signature" of a node from source buffer and populate the list of treesitter highlight groups for each token in the row.
	---The "signature" is tipically the first "row" in the node, e.g. the class name or function signature (including parameters).
	---NOTE: assumes all the text from node and children belongs to the same row from the source buffer.
	---@param start_node TSNode the node for which to extract the "signature" text
	---@param node TSNode current node being analyzed. On the first call it's the same as start_node, in recursive calls it's the current subnode below |start_node|
	---@param code_line string output parameter, updated with the full text from the source buffer corresponding to |start_node|
	---@param hl_groups HighlightingInfo[] list of highlighting groups extracted from the source buffer to be applied to the layout buffer
	---@param row integer 1-indexed number of the row where the layout for |start_node| should go
	---@param last_token_node TSNode? only used in recursive calls, used to compute the spacing to leave between tokens in the final extracted text
	---@return boolean, string the the first value tells if the recursion should continue or if it should be stopped. The second value is the extracted text
	local function recursively_find_text(start_node, node, code_line, hl_groups, row, last_token_node)
		if node:child_count() > 0 then
			local previous_token_node = last_token_node
			local keep_going = true
			for child_node, _ in node:iter_children() do
				keep_going, code_line = recursively_find_text(start_node, child_node, code_line, hl_groups, row, previous_token_node)
				if not keep_going then return false, code_line end
				previous_token_node = child_node
			end
			return true, code_line
		end

		local parent = node:parent()
		assert(parent ~= nil) -- at this point the node has at least 1 parent because of the for loop above
		if start_node:equal(parent) and node_in_token_list(node, stop_at_list) then return false, code_line end -- stop building the string when any of the stop tokens are found as direct children of the initial node
		if node_in_token_list(node, ignore_list) then return true, code_line end -- skip any token in the ignore list and continue

		local node_text = tsutils.get_node_text(node, source_buf)

		-- figure out how many spaces separate the current toke from the previous token
		-- NOTE: this assumes that all the tokens are on the same line
		if last_token_node == nil then last_token_node = node end
		local _, _, _, previous_token_end_col = last_token_node:range()
		local _, current_token_start_col, _, _ = node:range()
		local spaces = string.rep(' ', current_token_start_col - previous_token_end_col)

		local col_start = #code_line
		code_line = code_line .. spaces .. node_text
		local col_end = #code_line

		local hl_group = find_highlighting_group(node, source_buf)
		table.insert(hl_groups, {
			hl_group = hl_group,
			row = row-1,
			col_start = col_start,
			col_end = col_end,
		})

		return true, code_line
	end

	---@type HighlightingInfo[]
	local hl_groups = {}
	local lines = utils.tables.map(nodes, function(node, row)
		local depth = find_depth(node, node_types)
		local indentation = string.rep(' ', indent_width * depth)

		local code_line = indentation

		_, code_line = recursively_find_text(node, node, code_line, hl_groups, row)

		return code_line
	end)
	vim.api.nvim_buf_set_lines(scratch_buf, 0, 1, false, lines)
	vim.api.nvim_set_option_value('modifiable', false, { buf = scratch_buf })
	vim.api.nvim_set_option_value('buflisted', false, { buf = scratch_buf })
	vim.api.nvim_set_option_value('cursorline', true, { win = scratch_win })
	vim.api.nvim_set_option_value('shiftwidth', indent_width, { buf = scratch_buf })
	vim.api.nvim_set_option_value('foldmethod', 'indent', { win = scratch_win })

	apply_highlighting(hl_groups, scratch_buf)
end


---@param source_cursor_node TSNode?
---@param nodes CodeLayoutMapping
---@param scratch_win integer
local function move_to_current_node_in_code_layout(source_cursor_node, nodes, scratch_win)
	if source_cursor_node == nil then return end
	local parent_node = first_parent_of_type(source_cursor_node, { 'class_definition', 'function_definition' })

	if parent_node == nil then return end

	for line, node in ipairs(nodes) do
		if node:equal(parent_node) then
			vim.api.nvim_win_set_cursor(scratch_win, { line, 0 })
		end
	end
end

M.navigate_to_source = function(self)
	local position = vim.api.nvim_win_get_cursor(0)
	local node_row = position[1]
	local node = self.nodes[node_row]

	local row, col, _, _ = node:range()

	vim.api.nvim_set_current_win(self.source_win)
	vim.api.nvim_set_current_buf(self.source_buf)
	vim.api.nvim_win_set_cursor(self.source_win, { row + 1, col })
end

M.close_code_layout_window = function(self)
	vim.api.nvim_win_close(self.scratch_win, true)
	vim.api.nvim_buf_delete(self.scratch_buf, { unload = true, force = true })
end

---@param node_types string[]
---@return string
local function build_treesitter_query(node_types)
	return '[ (' .. table.concat(node_types, ') (') .. ') ] @result'
end

M.update = function (self)
	self.nodes = getMapping(self.source_buf, self.filetype, self.query_str)
	populateCodeLayoutBuffer(
		self.nodes,
		self.config.node_types,
		self.source_buf,
		self.scratch_buf,
		self.scratch_win,
		self.config.stop_at_tokens,
		self.config.ignore_tokens,
		self.indent_width
	)
	move_to_current_node_in_code_layout(self.source_cursor_node, self.nodes, self.scratch_win)
end

M.get_buf = function(self)
	return self.scratch_buf
end

---Constructor
---@param language_config CodeLayoutLanguageConfig
---@return CodeLayout
function M:new(language_config, indent_width)
	local o = {}
	setmetatable(o, self)
	self.__index = self

	self.config = language_config

	self.indent_width = indent_width

	self.source_win = vim.api.nvim_get_current_win()
	self.source_buf = vim.api.nvim_get_current_buf()
	self.filetype = vim.api.nvim_get_option_value('filetype', { buf = self.source_buf })
	self.source_cursor_node = vim.treesitter.get_node()

	self.query_str = build_treesitter_query(language_config.node_types)

	self.scratch_buf = vim.api.nvim_create_buf(true, true)
	self.scratch_win = vim.api.nvim_open_win(self.scratch_buf, true, {
		win = self.source_win,
		split = "right",
		vertical = true,
	})

	return o
end

return M
