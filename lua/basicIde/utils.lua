return {
	ensure_trailing_slash = function(path)
		if string.sub(path, #path, #path) == '/' then return path end
		return path .. '/'
	end,

	ensure_no_leading_slash = function(path)
		if string.sub(path, 1, 1) == '/' then return string.sub(path, 2) end
		return path
	end,

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

		if custom_options == nil then
			custom_options = {}
		end
		options = Deepmerge(options, custom_options)

		local buf = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_open_win(buf, true, options)

		return buf
	end,

	-- calls callback passing the output of the command and the exit code as a list of lines. Merges stdout and stderr
	runAndReturnOutput = function(command, callback, options)
		local output = {}
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
		local options = Deepmerge(options, default_options)

		return vim.fn.jobstart(command, options)
	end,
}
