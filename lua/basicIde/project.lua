local PROJECT_SETTINGS_FILE = '.nvim.proj.lua'

local function setup_dap_configurations(project_dap_configurations)
	if project_dap_configurations == nil then return end
	local dap = require('dap')

	for language, project_configurations in pairs(project_dap_configurations) do
		if dap.configurations[language] == nil then dap.configurations[language] = {} end

		for _, project_configuration in pairs(project_configurations) do
			for i, dap_config in pairs(dap.configurations[language]) do
				if dap_config.name == project_configuration.name then
					table.remove(dap.configurations[language], i)
				end
			end

			table.insert(dap.configurations[language], project_configuration)
		end
	end
end

local function apply_project_config()
	if not File_exists(PROJECT_SETTINGS_FILE) then return end

	local project_configuration = dofile(PROJECT_SETTINGS_FILE)

	setup_dap_configurations(project_configuration.dap_configurations)
end


return {
	use_deps = function(use)
	end,

	configure = function()
		apply_project_config()

		vim.api.nvim_create_autocmd('BufWritePost', {
			pattern = PROJECT_SETTINGS_FILE,
			desc = 'reload ' .. PROJECT_SETTINGS_FILE .. ' on save',
			callback = apply_project_config,
		})
	end,
}
