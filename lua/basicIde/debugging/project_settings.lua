local utils = require('basicIde.utils')

---Apply some preprocessing to the data coming from project settings.
---This is mainly meant to make it easier for the user to provide configuration without
---having to worry too much about lua/dap input requirements format.
---
---WARNING: despite the fact it returns the object, input is mutated
---@param project_configuration DapConfigurationExtended
---@return DapConfigurationExtended
local function preprocess_project_config(project_configuration)
	if type(project_configuration.args) == "string" then
		project_configuration.args = vim.split(project_configuration.args, " +", { plain = false, trimempty = true})
	end

	return project_configuration
end

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

			local processed_project_configuration = preprocess_project_config(project_configuration)
			table.insert(dap.configurations[language], processed_project_configuration)

			-- setup keymap if the extra keymap field is specified in the dap configuration at project setting level
			if project_configuration.keymap then
				vim.keymap.set('n', project_configuration.keymap,
					function()
						dap.run(project_configuration)
						if project_configuration.open_console_on_start then
							dapui.float_element('console', { width = 130, height = 60 })
						end
					end,
					{ desc = '[' .. project_configuration.type .. ']' .. ' debug: ' .. project_configuration.name })
			end
		end
	end
end

---Changes the configuration of all DAP entries to include the
---environment variables specified in the loader sections. It's necessary to stop worrying about
---which environment variables are loaded by centralizing hte configuration and make for a more
---uniform user experience.
---
---This assumes that custom variables have been already expanded in the loader settings
---and should be done after having loaded/created any other dynamic dap configuration (e.g. python coverage ones).
---@param loader_settings LoaderConfig
local function apply_environment_configurations(loader_settings)
	local dap = require('dap')

	local loader_environment = loader_settings.environment
	for _, dap_configurations in pairs(dap.configurations) do
		for _, dap_configuration in ipairs(dap_configurations) do
			if dap_configuration.env ~= nil then
				dap_configuration.env = utils.tables.deepmerge(utils.tables.deepcopy(loader_environment), dap_configuration.env)
			else
				dap_configuration.env = utils.tables.deepcopy(loader_environment)
			end
		end
	end
end

return {
	apply_custom_dap_configurations = apply_custom_dap_configurations,

	---@param project_settings ProjectSettings
	setup_project_settings = function(project_settings)
		local debugging_project_settings = project_settings.debugging

		local dap_configurations = debugging_project_settings.dap_configurations
		if dap_configurations == nil then return end

		apply_environment_configurations(project_settings.loader)

		-- Reload dap configurations on change without requiring to restart nvim.
		-- This is the reason why we have to remove existing dap configurations from the config list every time,
		-- but it's much more convenient for the user
		vim.api.nvim_create_autocmd('User', {
			pattern = 'ProjectSettingsChanged',
			desc = 'reload ' .. project_settings.PROJECT_SETTINGS_FILE .. ' on save',
			callback = function()
				apply_custom_dap_configurations(debugging_project_settings.dap_configurations)
			end,
		})
	end
}
