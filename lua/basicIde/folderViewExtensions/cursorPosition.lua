local view = require('nvim-tree.view')
local api = require('nvim-tree.api')
local Event = api.events.Event

local M = {
	_last_position = { 1, 0 },
	_should_apply = true,
}

M.get = function()
	local default = { 1, 0 }

	local window_id = view.get_winnr()
	if window_id == nil then
		return default
	end

	return vim.api.nvim_win_get_cursor(window_id)
end

M.setup = function(cursor_position)
	M._last_position = cursor_position

	api.events.subscribe(Event.TreeOpen, function()
		local bufnr = view.get_bufnr();

		vim.api.nvim_create_autocmd('BufWinLeave', {
			buffer = bufnr,
			callback = function()
				M._last_position = M.get()
			end,
		})

		vim.api.nvim_create_autocmd('BufUnload', {
			buffer = bufnr,
			callback = function()
				M._should_apply = true
			end,
		})
	end)

	api.events.subscribe(Event.TreeRendered, function()
		if M._should_apply then
			M.apply(M._last_position)
			M._should_apply = false -- nvim-tree already takes care of keeping the cursor position as long as the buffer is valid
		end
	end)
end

M.apply = function(cursor_position)
	view.set_cursor(cursor_position)
end

M.serialize = function(cursor_position)
	return tostring(cursor_position[1]) .. ',' .. tostring(cursor_position[2])
end

M.deserialize = function(raw_value)
	local row, column = string.gmatch(raw_value, '(%d+),(%d+)')()
	local cursor_position = { tonumber(row), tonumber(column) }

	return cursor_position
end

return M
