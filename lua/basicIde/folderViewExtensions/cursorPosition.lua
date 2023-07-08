local view = require('nvim-tree.view')

local M = {}

M.parse = function(raw_value)
	local row, column = string.gmatch(raw_value, '(%d+),(%d+)')()
	local cursor_position = { tonumber(row), tonumber(column) }

	return cursor_position
end

M.get = function()
	local default = { 1, 0 }

	local window_id = view.get_winnr()
	if window_id == nil then
		return default
	end

	return vim.api.nvim_win_get_cursor(window_id)
end

M.serialize = function(cursor_position)
	return tostring(cursor_position[1]) .. ',' .. tostring(cursor_position[2])
end

M.apply = function(cursor_position)
	local bufnr = view.get_bufnr()
	local buf_lines = vim.api.nvim_buf_line_count(bufnr)
	local windows = vim.fn.win_findbuf(bufnr)

	for _, window_id in pairs(windows) do
		if cursor_position[1] <= buf_lines then
			vim.api.nvim_win_set_cursor(window_id, cursor_position)
		end
	end
end

return M
