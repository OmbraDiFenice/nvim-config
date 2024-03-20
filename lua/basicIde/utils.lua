---@class Utils
local M = {}

---Ensures that the path string passed in has a trailing forward slash /
---@param path string
---@return string
M.ensure_trailing_slash = function(path)
	if string.sub(path, #path, #path) == '/' then return path end
	return path .. '/'
end

---Ensures that the path string passed in has no leading forward slash /
---@param path string
---@return string
M.ensure_no_leading_slash = function(path)
	while string.sub(path, 1, 1) == '/' do path = string.sub(path, 2) end
	return path
end

---Ensures that the path string passed in has no trailing forward slash /
---@param path string
---@return string
M.ensure_no_trailing_slash = function(path)
	while string.sub(path, #path, #path) == '/' do path = string.sub(path, 1, #path-1) end
	return path
end

---Removes any line of length 0 from the list of lines
---@param lines string[]
---@return string[] a new list of lines without the empty ones
M.remove_trailing_empty_lines = function(lines)
	local cleaned_lines = {}

	for i = #lines, 1, -1 do
		if #(lines[i]) ~= 0 then
			table.insert(cleaned_lines, 1, lines[i])
		end
	end

	return cleaned_lines
end

---Open a simple floating window with the given options. The purpose is to give a way to open a float
---window that's consistent across the IDE by providing some defaults for the normal options from |vim.api.nvim_open_win()|.
---@param bufnr? integer # buffer handle to open in the float window, or nil to open a new buffer
---@param custom_options? table # same options passed to |vim.api.nvim_open_win()|. Defaults to a float with a single border and centered in the current window. If provided, those defaults are still used as a base, but you can override whatever you want
---@return integer, integer # the bufnr of the buffer contained in the float and the window handle of the float window itself respectively
M.openFloatWindow = function(bufnr, custom_options)
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
	options = Deepmerge(options, custom_options)

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
	options = Deepmerge(options, default_options)

	return vim.fn.jobstart(command, options)
end

---Like runAndReturnOutput but waits until the called command terminates. Returns the output lines and the return code as return values
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
		Printlines(log_before)
	end
	M.runAndReturnOutput(command, function (output_lines)
		Printlines(output_lines)

		if log_after ~= nil then
			Printlines(log_after)
		end
	end, {})
end

---Return the highlighted text in visual mode
---
---taken from https://github.com/nvim-telescope/telescope.nvim/issues/1923 
---@return string
M.get_visual_selection = function ()
	vim.cmd('noau normal! "vy"')
	local text = vim.fn.getreg('v')
	vim.fn.setreg('v', {})

	if text == nil then return '' end

	text = string.gsub(text --[[@as string]], "\n", "")
	if #text > 0 then
		return text
	else
		return ''
	end
end

---Update status in lualine when a dap configuration starts.
---This is useful when you run tests multiple times, otherwise you might still have the last outcome displayed
---and not know exactly if you triggered the tests or not.
---@param message string
---@param color string?
---@return nil
M.update_lualine_debug_status = function (message, color)
	if color ~= nil then
		message = '%#' .. color .. '#' .. message
	end

	vim.api.nvim_exec_autocmds('User', {
		pattern = 'UpdateTestStatusBar',
		data = { message = message },
	})
end

---Parse the definition of a custom keymap from the config.
---This utility function can be used by different plugins and allow to have a
---standardized format for the configuration of custom keymaps in the IDE.
---@param mode_shortcut string keymap shortcut in the format '<mode> <shortcut>' (e.g. 'n <leader>X'). If <mode> is omitted it defaults to n
---@param keymap_def CustomKeymapDef
---@return string, string, fun(...), string # mode, shortcut, callback, description
M.parse_custom_keymap_config = function(mode_shortcut, keymap_def)
		local splits = Split(mode_shortcut)
		local mode
		local shortcut
		if #splits == 1 then
			mode = 'n'
			shortcut = splits[1]
		else
			mode = splits[1]
			shortcut = splits[2]
		end

		local desc = keymap_def.desc
		if desc == nil then desc = 'Custom keymap ' .. shortcut end

		local callback
		if type(keymap_def.fun) == "string" then
			local fun = keymap_def.fun
			---@cast fun string
			local start_log = nil
			local end_log = nil
			if keymap_def.verbose then
				start_log = 'starting ' .. desc
				end_log = desc .. ' completed'
			end
			callback = function () M.run(fun, start_log, end_log) end
		else
			callback = function (...) keymap_def.fun(...) end
		end

		return mode, shortcut, callback, desc
end

return M
