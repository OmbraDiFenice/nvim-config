return {
	---Ensures that the path string passed in has a trailing forward slash /
	---@param path string
	---@return string
	ensure_trailing_slash = function(path)
		if string.sub(path, #path, #path) == '/' then return path end
		return path .. '/'
	end,

	---Ensures that the path string passed in has no leading forward slash /
	---@param path string
	---@return string
	ensure_no_leading_slash = function(path)
		if string.sub(path, 1, 1) == '/' then return string.sub(path, 2) end
		return path
	end,

	---Open a simple floating window with the given options. The purpose is to give a way to open a float
	---window that's consistent across the IDE by providing some defaults for the normal options from |vim.api.nvim_open_win()|.
	---@param custom_options? table # same options passed to |vim.api.nvim_open_win()|. Defaults to a float with a single border and centered in the current window. If provided, those defaults are still used as a base, but you can override whatever you want
	---@return integer # the bufnr of the buffer contained in the float
	openFloatWindow = function(custom_options)
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

		local buf = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_open_win(buf, true, options)

		return buf
	end,

	---Runs `command` with |vim.fn.jobstart| and calls `callback` when the process ends with the output of the command and the job exit code as parameters.
	---
	---Merges stdout and stderr
	---@param command string[] | string # command to pass to |vim.fn.jobstart|
	---@param callback fun(output: string[], exit_code: integer): nil # the callback that will be invoked once the job terminates. The output of the job is passed as an array of lines
	---@param options any # options for |vim.fn.jobstart|. They will extend a set of basic options required to capture the job output, but they will be overwritten if you provide your own
	---@return integer # the job id of the spawned nvim job, as returned by |vim.fn.jobstart()|
	runAndReturnOutput = function(command, callback, options)
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
	end,

	---Return the highlighted text in visual mode
	---
	---taken from https://github.com/nvim-telescope/telescope.nvim/issues/1923 
	---@return string
	get_visual_selection = function ()
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
}
