local code_layout = require('basicIde.code_layout.code_layout')
local key_mapping = require('basicIde.key_mapping')

local master_keymap_descriptions = {
	open_layout = '[Code layout] open current code layout',
}

local buffer_keymap_descriptions = {
	close_layout = '[Code layout] close code layout',
	goto_and_close_layout = '[Code layout] goto to symbol and close layout',
}

---@return KeymapManager
local function make_buffer_keymap_manager(layout)
	return {
		keymap_callbacks = {
			close_layout = { callback = function() layout:close_code_layout_window() end, opts = {} },
			goto_and_close_layout = { callback = function() layout:navigate_to_source(); layout:close_code_layout_window() end, opts = {} },
		}
	}
end

---@param config CodeLayoutConfig
local function create_layout(config)
	local filetype = vim.bo.filetype
	local language_config = config.languages[filetype]
	if language_config == nil then
		vim.notify('Code layout for language "' .. filetype .. '" not configured', vim.log.levels.WARN)
		return
	end

	local layout = code_layout:new(language_config, config.indent_width)
	layout:update()

	local buffer_keymap_manager = make_buffer_keymap_manager(layout)
	key_mapping.setup_keymaps(buffer_keymap_descriptions, buffer_keymap_manager, config.keymaps)
end

---@return KeymapManager
local function make_master_keymap_manager(config)
	return {
		keymap_callbacks = {
			open_layout = { callback = function() create_layout(config) end, opts = {} },
		}
	}
end

---@type IdeModule
return {
	use_deps = function()
	end,

	configure = function(project_settings)
		local config = project_settings.code_layout

		local master_keymap_manager = make_master_keymap_manager(config)
		key_mapping.setup_keymaps(master_keymap_descriptions, master_keymap_manager, config.keymaps)
	end
}
