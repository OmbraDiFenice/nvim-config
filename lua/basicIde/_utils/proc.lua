local M = {}

---Open a simple floating window with the given options. The purpose is to give a way to open a float
---window that's consistent across the IDE by providing some defaults for the normal options from |vim.api.nvim_open_win()|.
---@param bufnr? integer # buffer handle to open in the float window, or nil to open a new buffer
---@param custom_options? table # same options passed to |vim.api.nvim_open_win()|. Defaults to a float with a single border and centered in the current window. If provided, those defaults are still used as a base, but you can override whatever you want
---@return integer, integer # the bufnr of the buffer contained in the float and the window handle of the float window itself respectively
M.openFloatWindow = function(bufnr, custom_options)
	local utils = require('basicIde.utils')

	local win_width  = vim.api.nvim_win_get_width(0)
	local win_height = vim.api.nvim_win_get_height(0)

	local perc       = 0.1

	local width      = math.floor(win_width - (win_width * perc) * 2)
	local height     = math.floor(win_height - (win_height * perc) * 2)

	local orig_col   = math.floor(win_width * perc)
	local orig_row   = math.floor(win_height * perc)

	local options    = {
		relative = 'win',
		row = orig_row,
		col = orig_col,
		width = width,
		height = height,
		border = 'single',
	}

	if custom_options == nil then custom_options = {} end
	options = utils.tables.deepmerge(options, custom_options)

	if bufnr == nil then bufnr = vim.api.nvim_create_buf(false, false) end

	local winnr = vim.api.nvim_open_win(bufnr, true, options)

	return bufnr, winnr
end

---Runs `command` with |vim.fn.jobstart| and calls `callback` when the process ends with the output of the command and the job exit code as parameters.
---
---Merges stdout and stderr
---@param command string[] | string # command to pass to |vim.fn.jobstart|
---@param callback fun(output: string[], exit_code: integer): nil # the callback that will be invoked once the job terminates. The output of the job is passed as an array of lines
---@param options any # options for |vim.fn.jobstart|. They will extend a set of basic options required to capture the job output, but they will be overwritten if you provide your own
---@return integer # the job id of the spawned nvim job, as returned by |vim.fn.jobstart()|
M.runAndReturnOutput = function(command, callback, options)
	local utils = require('basicIde.utils')

	---@type string[]
	local output = {}

	---@param dst string[]
	---@param lines string[]
	local function appendLines(dst, lines)
		for _, line in ipairs(lines) do
			table.insert(dst, line)
		end
	end

	local default_options = {
		clear_env = false,
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, lines) appendLines(output, lines) end,
		on_stderr = function(_, lines) appendLines(output, lines)	end,
		on_exit = function(_, exit_code) callback(output, exit_code) end,
	}

	if options == nil then options = {} end
	options = utils.tables.deepmerge(options, default_options)

	return vim.fn.jobstart(command, options)
end

---Like runAndReturnOutput but waits until the called command terminates. Returns the output lines and the return code as return values
---@param command string[] | string
---@return string[], integer
---@see runAndReturnOutput
M.runAndReturnOutputSync = function(command, options)
	local output
	local return_code
	local job_id = M.runAndReturnOutput(command, function(inner_output, inner_return_code)
		output = inner_output
		return_code = inner_return_code
	end, options)

	vim.fn.jobwait({job_id})
	return output, return_code
end

---Convenience method to run a command. It simply prints any output (combining stdout and stderr) and exits.
---If you want to perform actions when the command completes use `runAndReturnOutput` instead.
---@param command string[]|string
---@param log_before nil|string[]|string # a string to log before the start of the command, or nil to skip the log
---@param log_after nil|string[]|string # a string to log after the end of the command, or nil to skip the log
---@return nil
---@see runAndReturnOutput
M.run = function(command, log_before, log_after)
	if log_before ~= nil then
		vim.notify(log_before)
	end
	M.runAndReturnOutput(command, function (output_lines)
		vim.notify(output_lines)

		if log_after ~= nil then
			vim.notify(log_after)
		end
	end, {})
end

return M
