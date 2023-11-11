local PROJECT_SETTINGS_FILE = '.nvim.proj.lua'

local default_settings = {
	format_on_save = { -- WARNING: if enabled together with autosave it will pollute the undo history and you won't be able to undo changes anymore
		enabled = false, -- 1. you make a change -> autosave triggers -> changes go to undo history
                     -- 2. buffer is autoformatted -> buffer is changed -> autosave triggers again -> autoformatting changes go to undo history
                     -- 3. you want to undo changes made at point 1, but:
                     --    - hitting 'u' actually undoes the reformatting from point 2
                     --    - that triggers autoformat again
                     --    - you're back to the change you wanted to undo
		keymaps = {
			format_current_buffer = '<F7>',
		}
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
