local utils = require('basicIde.utils')

---@class AnchorNode
---@field root_node TSNode
---@field root_capture string -- capture name of the node to store, which is different from the captures getting e.g. the function name or parameter list since they point to different nodes.
---@field captures table<string, TSNode>
---@field formatted_text string

---@class SmartCodeLayout : CodeLayout
---@field config CodeLayoutLanguageConfig
---@field indent_width integer
---@field source_win integer
---@field source_buf integer
---@field filetype string
---@field source_cursor_node TSNode?
---@field scratch_win integer
---@field scratch_buf integer
---@field nodes AnchorNode[]

local M = {}

---@param queries CodeLayoutQuery[]
local function validate_queries(queries)
	for i, query_def in ipairs(queries) do
		local root_capture = query_def.root_capture or 'root'
		if query_def.query:find('@'..root_capture) == nil then
			vim.notify('Query ' .. i .. ' does not use any capture root. Check your code_layout config', vim.log.levels.ERROR)
		end
	end
end

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

---@param self SmartCodeLayout
M.navigate_to_source = function(self)
	local position = vim.api.nvim_win_get_cursor(0)
	local node_row = position[1]
	local anchor_node = self.nodes[node_row]

	local row, col, _, _ = anchor_node.root_node:range()

	vim.api.nvim_set_current_win(self.source_win)
	vim.api.nvim_set_current_buf(self.source_buf)
	vim.api.nvim_win_set_cursor(self.source_win, { row + 1, col })
end

---@param self SmartCodeLayout
M.close_code_layout_window = function(self)
	vim.api.nvim_win_close(self.scratch_win, true)
	vim.api.nvim_buf_delete(self.scratch_buf, { unload = true, force = true })
end

---@param anchor_node AnchorNode
---@param format string
---@param source_buf integer
---@return string
local function format_anchor_node(anchor_node, format, source_buf)
	local formatted_text = format
	for name, capture_node in pairs(anchor_node.captures) do
		formatted_text = string.gsub(formatted_text, '${' .. name .. '}', vim.treesitter.get_node_text(capture_node, source_buf))
	end
	formatted_text = string.gsub(formatted_text, ' *${[^}]*}', '')
	return vim.fn.trim(formatted_text)
end

---@param root TSNode
---@param query vim.treesitter.Query
---@param bufnr integer
---@param format string
---@param root_capture string
---@return AnchorNode[]
local function find_anchor_nodes(root, query, bufnr, format, root_capture)
	local anchor_nodes = {}

	for _, matches, _ in query:iter_matches(root, bufnr, root:start(), root:end_(), { all = true }) do
		local captures = {}
		local found_root_capture = nil
		local found_root_node = nil

		for capture_idx, capture_nodes in pairs(matches) do
			for _, capture_node in ipairs(capture_nodes) do
				local capture_name = query.captures[capture_idx]
				captures[capture_name] = capture_node

				if capture_name == root_capture then
					found_root_capture = capture_name
					found_root_node = capture_node
				end
			end
		end

		if found_root_capture ~= nil and found_root_node ~= nil then
			---@type AnchorNode
			local anchor_node = {
				root_node = found_root_node,
				root_capture = found_root_capture,
				captures = captures,
				formatted_text = '',
			}
			anchor_node.formatted_text = format_anchor_node(anchor_node, format, bufnr)

			table.insert(anchor_nodes, anchor_node)
		end
	end

	return anchor_nodes
end

---@param anchor_nodes AnchorNode[]
---@param node_types string[]
---@param indent_width integer
---@return string[] the content of the scratch buffer showing the code layout
local function populate_code_layout_buffer(anchor_nodes, node_types, indent_width)
	return utils.tables.map(anchor_nodes, function(anchor_node)
		local depth = find_depth(anchor_node.root_node, node_types)
		local indentation = string.rep(' ', indent_width * depth)
		return indentation .. anchor_node.formatted_text
	end)
end

---@param source_cursor_node TSNode?
---@param anchor_nodes AnchorNode[]
---@param node_types string[]
---@param scratch_win integer
local function move_to_current_node_in_code_layout(source_cursor_node, anchor_nodes, node_types, scratch_win)
	if source_cursor_node == nil then return end
	local parent_node = first_parent_of_type(source_cursor_node, node_types)

	if parent_node == nil then return end

	for line, anchor_node in ipairs(anchor_nodes) do
		if anchor_node.root_node:equal(parent_node) then
			vim.api.nvim_win_set_cursor(scratch_win, { line, 0 })
		end
	end
end

---@param self SmartCodeLayout
M.update = function (self)
	local parser = vim.treesitter.get_parser(self.source_buf)
	local trees = parser:parse()
	local tree = trees[1]

	for _, query_config in ipairs(self.config.queries) do
		local query = vim.treesitter.query.parse(self.filetype, query_config.query)
		local new_nodes = find_anchor_nodes(tree:root(), query, self.source_buf, query_config.format, query_config.root_capture or "root")
		vim.list_extend(self.nodes, new_nodes) -- mutates dest list
	end

	table.sort(
		self.nodes,
		---@param a AnchorNode
		---@param b AnchorNode
		---@return boolean
		function(a, b) return a.root_node:start() < b.root_node:start() end
	)

	local scratch_buf_data = populate_code_layout_buffer(
		self.nodes,
		self.config.node_types,
		self.indent_width
	)

	vim.api.nvim_set_option_value('modifiable', true, { buf = self.scratch_buf })
	vim.api.nvim_buf_set_lines(self.scratch_buf, 0, 1, false, scratch_buf_data)
	vim.api.nvim_set_option_value('modifiable', false, { buf = self.scratch_buf })

	move_to_current_node_in_code_layout(self.source_cursor_node, self.nodes, self.config.node_types, self.scratch_win)
end

---@param self SmartCodeLayout
M.get_buf = function(self)
	return self.scratch_buf
end

---Constructor
---@param language_config CodeLayoutLanguageConfig
---@return SmartCodeLayout
function M:new(language_config, indent_width)
	local o = {
		nodes = {},
	}
	setmetatable(o, self)
	self.__index = self

	self.config = language_config
	validate_queries(self.config.queries)

	self.indent_width = indent_width

	self.source_win = vim.api.nvim_get_current_win()
	self.source_buf = vim.api.nvim_get_current_buf()
	self.filetype = vim.api.nvim_get_option_value('filetype', { buf = self.source_buf })
	self.source_cursor_node = vim.treesitter.get_node()

	self.scratch_buf = vim.api.nvim_create_buf(true, true)
	self.scratch_win = vim.api.nvim_open_win(self.scratch_buf, true, {
		win = self.source_win,
		split = "right",
		vertical = true,
	})

	vim.api.nvim_set_option_value('filetype', self.filetype, { buf = self.scratch_buf })
	vim.api.nvim_set_option_value('modifiable', false, { buf = self.scratch_buf })
	vim.api.nvim_set_option_value('buflisted', false, { buf = self.scratch_buf })
	vim.api.nvim_set_option_value('cursorline', true, { win = self.scratch_win })
	vim.api.nvim_set_option_value('shiftwidth', indent_width, { buf = self.scratch_buf })
	vim.api.nvim_set_option_value('foldmethod', 'indent', { win = self.scratch_win })

	return o
end

return M
