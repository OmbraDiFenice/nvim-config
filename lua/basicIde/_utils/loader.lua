local _proc = require('basicIde._utils.proc')

local M = {}

local last_title = ''
---set terminal window title if supported by the launching terminal emulator
---@param title string
M.set_title = function(title)
	local script = os.getenv("SET_TITLE_SCRIPT")
	if script == nil or #os.getenv("SET_TITLE_SCRIPT") == 0 then return end
	_proc.run('$SET_TITLE_SCRIPT ' .. vim.fn.shellescape(title, 1))
	last_title = title
end

---returns the last title set on the window
---@return string
M.get_title = function()
	return last_title
end

return M
