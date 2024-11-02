local utils = require('basicIde.utils')

---@class KeymapCallbackSetting
---@field callback fun()
---@field opts table<string, any>

---@class KeymapManager
---@field keymap_callbacks table<string, KeymapCallbackSetting> maps each action to the respective code implementing that action behavior

---Adds the keymaps corresponding to the actions in `keymap_descriptions`.
---The callback and options are fixed by the IDE and must come from the manager, while the actual keymaps to be associated to it
---can be set from the user and are passed in `custom_keymaps`.
---@param keymap_descriptions table<string, string> action name -> IDE description for that action
---@param manager KeymapManager
---@param custom_keymaps table<string, string[]> the custom keymap list (can be more than one) for each action in keymap_descriptions. All actions must be mapped, either from custom settings or getting their default
local function setup_keymaps(keymap_descriptions, manager, custom_keymaps)
	for action, keymap_description in pairs(keymap_descriptions) do
		local keymap_def = {
			desc = keymap_description,
			fun = manager.keymap_callbacks[action].callback
		}

		for _, custom_shortcut_mode in ipairs(custom_keymaps[action]) do
			local mode, shortcut, callback, description = utils.parse_custom_keymap_config(custom_shortcut_mode, keymap_def)
			local options = utils.tables.deepmerge({ desc = description }, manager.keymap_callbacks[action].opts)

			vim.keymap.set(mode, shortcut, callback, options)
		end
	end
end


return {
	setup_keymaps = setup_keymaps,
}
