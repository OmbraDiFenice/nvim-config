local _proc = require('basicIde._utils.proc')

local M = {}

local last_title = ''
---set terminal window title if supported by the launching terminal emulator
---@param title string
M.set_title = function(title)
	_proc.run('$SET_TITLE_SCRIPT ' .. title)
	last_title = title
end

---returns the last title set on the window
---@return string
M.get_title = function()
	return last_title
end

return M
