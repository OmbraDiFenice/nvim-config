local _proc = require('basicIde._utils.proc')

local M = {}

---set terminal window title if supported by the launching terminal emulator
---@param title string
M.set_title = function(title)
	_proc.run('$SET_TITLE_SCRIPT ' .. title)
end

return M
