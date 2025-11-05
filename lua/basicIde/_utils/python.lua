local M = {}

function M.create_venv(done_cb)
	local utils = require('basicIde.utils')
	vim.notify("creating venv...", vim.log.levels.INFO)
	utils.proc.runAndReturnOutput("python3 -m venv venv", function(output_lines, exit_code)
		if exit_code ~= 0 then
			vim.notify(table.concat(output_lines, '\n'), vim.log.levels.ERROR)
			done_cb(output_lines, exit_code)
			return
		end
		vim.notify("new python venv created, restart neovim to to use it", vim.log.levels.INFO)
		done_cb(output_lines, exit_code)
	end)
end

return M
