local view = require('nvim-tree.view')

return {
	parse = function(raw_value)
		local row, column = string.gmatch(raw_value, '(%d+),(%d+)')()
		local cursor_position = { tonumber(row), tonumber(column) }
		print('found cursor position at ' .. cursor_position[1] .. ',' .. cursor_position[2])

		return cursor_position
	end,

	get = function()
		local default = { 0, 0 }

		local window_id = view.get_winnr()
		if window_id == nil then
			return default
		end

		return vim.api.nvim_win_get_cursor(window_id)
	end,

	serialize = function(cursor_position)
		return tostring(cursor_position[1]) .. ',' .. tostring(cursor_position[2])
	end,

	apply = function(cursor_position)
		local window_id = view.get_winnr()
		print('window id: ' .. tostring(window_id))

		if window_id ~= nil then
			print('setting cursor at position ' .. cursor_position[1] .. ',' .. cursor_position[2])
			vim.api.nvim_win_set_cursor(window_id, cursor_position)
		end
	end
}
