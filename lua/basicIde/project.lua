local PROJECT_SETTINGS_FILE = '.nvim.proj.lua'

---@class FormatOnSaveKeymapsSettings
---@field format_current_buffer string

---@class FormatOnSaveSettings
---@field enabled boolean
---@field keymaps FormatOnSaveKeymapsSettings

---@class DapConfigurationExtended: Configuration
---@field unittest? boolean
---@field keymap string
---@field keymap_coverage string
---@field is_coverage? boolean

---@class DapConfigurationExtendedPython: DapConfigurationExtended
---@field args string[]
---@field module string

---@class DapSessionExtended: Session
---@field is_coverage? boolean

---@class DebuggingSettings
---@field dap_configurations? DapConfigurationExtended

---@class TerminalSettings
---@field init_environment_cmd string

---@class RemoteSyncSettings
---@field enabled boolean
---@field sync_on_save boolean
---@field remote_user? string
---@field remote_host? string
---@field mappings string[][]

---@class ProjectSettings
---@field PROJECT_SETTINGS_FILE string
---@field virtual_environment? string
---@field format_on_save FormatOnSaveSettings
---@field debugging DebuggingSettings
---@field terminal TerminalSettings
---@field remote_sync RemoteSyncSettings
local default_settings = {
	virtual_environment = nil,
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
	},
	remote_sync = {
		enabled = false,
		sync_on_save = true,
		remote_user = nil, -- required
		remote_host = nil, -- required
		mappings = { -- required
			-- { local_prefix_dir, remote_prefix_dir },
			-- ...
		},
	}
}

return {
	load_settings = function()
		local settings = Deepcopy(default_settings)

		if File_exists(PROJECT_SETTINGS_FILE) then
			local custom_settings = dofile(PROJECT_SETTINGS_FILE)
			---@cast custom_settings ProjectSettings
			settings = Deepmerge(settings, custom_settings)
		end

		-- Read only field.
		-- It's intentionally not customizable from project file,
		-- only available to be referenced by plugins if needed (see e.g. debugging)
		settings.PROJECT_SETTINGS_FILE = PROJECT_SETTINGS_FILE

		return settings
	end
}
