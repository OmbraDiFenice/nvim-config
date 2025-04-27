---@class Utils
local M = {
	paths = require('basicIde._utils.strings'),
	proc = require('basicIde._utils.proc'),
	files = require('basicIde._utils.files'),
	tables = require('basicIde._utils.tables'),
	loader = require('basicIde._utils.loader'),
	popup_menu = require('basicIde._utils.popup_menu'),
}

---Returns the directory to be used to store data related to the current nvim session.
---@return string # the full path to the folder holding session data
M.get_data_directory = function()
	local data_path = vim.fn.stdpath("data")
	local cwd_path = vim.fn.getcwd()
	---@cast data_path string
	---@cast cwd_path string
	return M.paths.ensure_no_trailing_slash(M.paths.ensure_trailing_slash(data_path) .. "sessions/" .. M.paths.ensure_no_leading_slash(cwd_path))
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

---Return the highlighted text in visual mode
---For some reason this one works when used as callback from mouse popup menu,
---while the other one works when used from i.e. the search component.
---
---taken from https://stackoverflow.com/a/6271254
---@return string
M.get_visual_selection2 = function()
	local start = vim.fn.getpos("'<")
	local end_ = vim.fn.getpos("'>")

	local bufnr = start[1]
	local line_start = start[2]
	local column_start = start[3]
	local line_end = end_[2]
	local column_end = end_[3]

	return table.concat(vim.api.nvim_buf_get_text(bufnr, line_start - 1, column_start - 1, line_end - 1, column_end, {}), "\n")
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
		local splits = M.paths.split(mode_shortcut)
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
			callback = function () M.proc.run(fun, true, start_log, end_log) end
		else
			--- must return the value from fun to enable cases where we use opts.expr = true
			--- to evaluate the return as a vim expression
			callback = function (...) return keymap_def.fun(...) end
		end

		return mode, shortcut, callback, desc
end

---Debounce the passed function so that it's not called more than once
---@param options? { timeout: integer, timer: userdata? }
---@param fn fun(...)
---@return unknown
M.debounce = function (options, fn, ...)
	local defaults = {
		timeout = 1000, -- ms
		timer = nil,
	}
	local actual_options = M.tables.deepmerge(defaults, options or {})

	local timer = actual_options.timer
	if timer ~= nil then timer:stop() end

	timer = vim.uv.new_timer()
	local args = ...

	timer:start(actual_options.timeout, 0, vim.schedule_wrap(function()
		timer:stop()
		fn(args)
		timer = nil
	end))

	return timer
end

function M.get_buf_var(buf, var_name, default_value)
  local s, v = pcall(function()
    return vim.api.nvim_buf_get_var(buf, var_name)
  end)
  if s then return v else return default_value end
end

return M
