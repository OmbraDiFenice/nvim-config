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

---@param template_name string
---@param project_settings ProjectSettings
local function get_external_script_template(template_name, project_settings)
	local template = {
		args = {},
		cwd = '.',
	}

	if template_name == 'busted-directory' then
		template.command = { project_settings.IDE_DIRECTORY .. '/debugging/languages/lua/PlenaryBustedDirectory' }
		template.args = { '.' }
	else
		vim.notify('Unable to find external script template named ' .. template_name, vim.log.levels.ERROR)
	end

	return template
end

local external_scripts_keymaps = {}

local function delete_external_script_keymaps()
	for _, external_script_keymap in ipairs(external_scripts_keymaps) do
		local mode = external_script_keymap[1]
		local keymap = external_script_keymap[2]
		pcall(vim.keymap.del, mode, keymap) -- in case the mapping was removed by hand before the settings editing
	end
	external_scripts_keymaps = {}
end

---@param project_settings ProjectSettings
local function create_external_script_keymaps(project_settings)
	local toggleterm = require('toggleterm.terminal')
	local external_scripts = project_settings.debugging.external_scripts

	local default_external_script = {
		template = nil,
		args = {},
		cwd = '.',
		open_console_on_start = false,
	}

	for i, external_script in ipairs(external_scripts) do
		external_script = vim.tbl_extend('force', default_external_script, external_script)

		local display_name = external_script.name or ('External Script ' .. i)

		local template = external_script
		if external_script.template ~= nil then
			template = get_external_script_template(external_script.template, project_settings)
			display_name = '[' .. external_script.template .. '] ' .. display_name
		end

		local script_desc = vim.tbl_extend('force', template, external_script)

		vim.keymap.set('n', external_script.keymap, function()
			local command = utils.tables.concat(script_desc.command, script_desc.args)
			local terminal = toggleterm.Terminal:new({
				cmd = table.concat(command, ' '),
				dir = template.cwd,
				close_on_exit = false,
				display_name = display_name,
				direction = 'float',
				on_exit = function(term)
					if not external_script.open_console_on_start and not term:is_open() then
						term:open()
						term:set_mode('i')
					end
				end
			})

			if external_script.open_console_on_start then
				terminal:open()
			else
				vim.notify('Starting ' .. display_name)
				terminal:spawn()
			end

		end, { desc = display_name })
		table.insert(external_scripts_keymaps, {'n', external_script.keymap})
	end
end

return {
	apply_custom_dap_configurations = apply_custom_dap_configurations,
	create_external_script_keymaps = create_external_script_keymaps,

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
				delete_external_script_keymaps()
				create_external_script_keymaps(project_settings)
			end,
		})
	end
}
