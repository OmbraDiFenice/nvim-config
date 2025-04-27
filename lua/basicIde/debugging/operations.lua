local dap = require('dap')
local utils = require('basicIde.utils')

local M = {}

function M.send_to_repl()
	local selection = utils.get_visual_selection2()
	dap.repl.execute(selection)
end

return M
