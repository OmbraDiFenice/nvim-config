local stack = require('basicIde.editor.stack')

---@class BufferStackData
---@field buf number
---@field file string

local buffer_stack = stack:new()

---Callback to call to maintain the stack
---@param stack_data BufferStackData
local function move_to_buffer(stack_data)
	local last_stack_data = buffer_stack:top()
	if last_stack_data ~= nil and (stack_data.buf == last_stack_data.buf or stack_data.file == last_stack_data.file) then
		buffer_stack:pop()
	else
		buffer_stack:push(stack_data)
	end
end

local function init()
	vim.api.nvim_create_autocmd({'BufLeave'}, {
		callback = function(data)
			---@type BufferStackData
			local stack_data = {
				buf = data.buf,
				file = data.file,
			}
			move_to_buffer(stack_data)
		end,
	})
end

return {
	init = init,
	move_to_buffer = move_to_buffer,
}
