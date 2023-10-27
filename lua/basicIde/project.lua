local PROJECT_SETTINGS_FILE = '.nvim.proj.lua'

local default_settings = {
	format_on_save = {
		enabled = true,
	},
	debugging = {
		dap_configurations = nil,
	},
	terminal = {
		init_environment_cmd = '[[ -d ${VIRTUAL_ENV+x} ]] || source "$VIRTUAL_ENV/bin/activate" ; clear'
	}
}

return {
	load_settings = function()
		local settings = Deepcopy(default_settings)

		if File_exists(PROJECT_SETTINGS_FILE) then
			local custom_settings = dofile(PROJECT_SETTINGS_FILE)
			settings = Deepmerge(settings, custom_settings)
		end

		-- Read only field.
		-- It's intentionally not customizable from project file,
		-- only available to be referenced by plugins if needed (see e.g. debugging)
		settings.PROJECT_SETTINGS_FILE = PROJECT_SETTINGS_FILE

		return settings
	end
}
