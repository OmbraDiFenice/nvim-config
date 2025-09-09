local utils = require('basicIde.utils')

---@param log_level vim.log.levels
---@return string
local function log_level_to_string(log_level)
	if log_level == vim.log.levels.TRACE then return "TRACE" end
	if log_level == vim.log.levels.DEBUG then return "DEBUG" end
	if log_level == vim.log.levels.INFO then return "INFO" end
	if log_level == vim.log.levels.WARN then return "WARN" end
	if log_level == vim.log.levels.ERROR then return "ERROR" end
	return ""
end

---@param log_level vim.log.levels
---@return "low"|"normal"|"critical"
local function log_level_to_urgency(log_level)
	if log_level == vim.log.levels.TRACE then return "low" end
	if log_level == vim.log.levels.DEBUG then return "low" end
	if log_level == vim.log.levels.INFO then return "normal" end
	if log_level == vim.log.levels.WARN then return "normal" end
	if log_level == vim.log.levels.ERROR then return "critical" end
	return "normal"
end

---@type IdeModule
return {
	use_deps = function(use)
		use {
			'rcarriga/nvim-notify',
		}

		use {
			'mrded/nvim-lsp-notify',
		}
	end,

	configure = function(project_settings)
		local telescope = require('telescope')
		telescope.load_extension('notify')
		vim.keymap.set('n', '<leader>sn', telescope.extensions.notify.notify, { desc = "Search in notifications" })

		local falled_back_msg
		if project_settings.editor.notifications.strategy == "system" and vim.fn.executable('notify-send') == 0 then
			project_settings.editor.notifications.strategy = "nvim-float"
			falled_back_msg = "system notification strategy cannot be used, falling back to nvim-float"
		end

		if project_settings.editor.notifications.strategy == "system" and falled_back_msg == nil then
			vim.notify = function(msg, level, options)
				if level == nil then
					level = vim.log.levels.INFO
				end
				local icon = project_settings.editor.notifications.system_configs.icons[level]
				local cmd = { "notify-send", "--print-id", "--app-name", "nvim basicIde" }
				if project_settings.editor.notifications.system_configs.transient then
					table.insert(cmd, "--transient")
				end
				if icon ~= nil then
					cmd = utils.tables.concat(cmd, { "--icon", icon })
				end
				if options ~= nil and options.replace ~= nil then
					cmd = utils.tables.concat(cmd, { "--replace-id", options.replace })
				end
				cmd = utils.tables.concat(cmd, { "--urgency", log_level_to_urgency(level), log_level_to_string(level), msg })
				local notification_id, _ = utils.proc.runAndReturnOutputSync(cmd, {})
				return tonumber(notification_id[1])
			end
		elseif project_settings.editor.notifications.strategy == "nvim-float" then
			local notify = require('notify')
			notify.setup({
				timeout = 1500,
				top_down = false,
				render = 'wrapped-compact',
			})

			vim.notify = function(msg, ...)
				local output = tostring(msg)
				if type(msg) == "table" then
					local lines = utils.tables.map(msg, tostring)
					output = table.concat(lines, '\n')
				end
				return notify(output, ...)
			end
		end

		if falled_back_msg ~= nil then
			vim.notify(falled_back_msg, vim.log.levels.WARN)
		end

		if project_settings.lsp.notifications.enabled then
			require('lsp-notify').setup({})
		end
	end
}
