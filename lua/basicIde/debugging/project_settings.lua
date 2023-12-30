---Adds the dap configurations from projects settings to the system dap configurations.
---Ensures that there are no duplicates even if called multiple times.
---@param dap_configurations table<string, DapConfigurationExtended[]>
---@return nil
local function apply_custom_dap_configurations(dap_configurations)
	local dap = require('dap')
	local dapui = require('dapui')

	for language, project_configurations in pairs(dap_configurations) do
		if dap.configurations[language] == nil then dap.configurations[language] = {} end

		for _, project_configuration in pairs(project_configurations) do
			-- remove a previous configuration with the same name if present
			for i, dap_config in pairs(dap.configurations[language]) do
				if dap_config.name == project_configuration.name then
					table.remove(dap.configurations[language], i)
				end
			end

			table.insert(dap.configurations[language], project_configuration)

			-- setup keymap if the extra keymap field is specified in the dap configuration at project setting level
			if project_configuration.keymap then
				vim.keymap.set('n', project_configuration.keymap,
					function()
						dap.run(project_configuration)
						if project_configuration.open_console_on_start then
							local current_win = vim.api.nvim_get_current_win()
							vim.cmd [[ vsplit ]]
							local console_win = vim.api.nvim_get_current_win()
							local console_buf = dapui.elements.console.buffer()
							vim.api.nvim_buf_set_var(console_buf, 'close_strategy', 'force_purge') -- TODO this only works well when closing with editor.close_all(), otherwise the session will store a console buffer which cannot be restored
							vim.api.nvim_win_set_buf(console_win, console_buf)
							vim.api.nvim_set_current_win(current_win)
						end
					end,
					{ desc = '[' .. project_configuration.type .. ']' .. ' debug: ' .. project_configuration.name })
			end
		end
	end
end

---@param project_settings ProjectSettings
return function(project_settings)
	local debugging_project_settings = project_settings.debugging

	local dap_configurations = debugging_project_settings.dap_configurations
	if dap_configurations == nil then return end

	apply_custom_dap_configurations(dap_configurations)

	-- Reload dap configurations on change without requiring to restart nvim.
	-- This is the reason why we have to remove existing dap configurations from the config list every time,
	-- but it's much more convenient for the user
	vim.api.nvim_create_autocmd('BufWritePost', {
		pattern = project_settings.PROJECT_SETTINGS_FILE,
		desc = 'reload ' .. project_settings.PROJECT_SETTINGS_FILE .. ' on save',
		callback = apply_custom_dap_configurations,
	})
end
