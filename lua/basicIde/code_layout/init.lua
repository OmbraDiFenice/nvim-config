local code_layout = require('basicIde.code_layout.code_layout')
local smart_code_layout = require('basicIde.code_layout.smart_code_layout')
local key_mapping = require('basicIde.key_mapping')

local master_keymap_descriptions = {
	open_layout = '[Code layout] open current code layout',
}

local buffer_keymap_descriptions = {
	close_layout = '[Code layout] close code layout',
	goto_and_close_layout = '[Code layout] goto to symbol and close layout',
	scroll_to = '[Code layout] scroll to the selected symbol but stays in code layout',
}

local function blink_line(win, repeat_delay)
	repeat_delay = repeat_delay or 100
	win = win or vim.api.nvim_get_current_win()
	local initial_cursorline = vim.api.nvim_get_option_value('cursorline', { win = win })

	local function set(on) vim.schedule(function () vim.api.nvim_set_option_value('cursorline', on, { win = win}) end) end

	local timer = vim.uv.new_timer()
	local count = 6 -- blink 3 times => 3 * 2 to account for the on/off cycle
	local current = initial_cursorline
	timer:start(0, repeat_delay, function()
		if count <= 0 then
			timer:stop()
			timer:close()
			set(initial_cursorline)
			return
		end

		current = not current
		set(current)
		count = count - 1
	end)
end

---@return KeymapManager
local function make_buffer_keymap_manager(layout)
	return {
		keymap_callbacks = {
			close_layout = { callback = function() layout:close_code_layout_window() end, opts = { buffer = layout.scratch_buf } },
			goto_and_close_layout = { callback = function() layout:navigate_to_source(); layout:close_code_layout_window() end, opts = { buffer = layout.scratch_buf } },
			scroll_to = { callback = function()
				layout:navigate_to_source()
				blink_line(layout.source_win)
				vim.api.nvim_set_current_win(layout.scratch_win)
			end, opts = { buffer = layout.scratch_buf } },
		}
	}
end

---@param config CodeLayoutConfig
---@return CodeLayout?
local function create_layout(config)
	local filetype = vim.bo.filetype
	local language_config = config.languages[filetype]
	if language_config == nil then
		vim.notify('Code layout for language "' .. filetype .. '" not configured', vim.log.levels.WARN)
		return
	end

	local layout
	if config.strategy == 'smart' then
		layout = smart_code_layout:new(language_config, config.indent_width)
	elseif config.strategy == 'legacy' then
		layout = code_layout:new(language_config, config.indent_width)
	else
		vim.notify('Unknown code layout strategy "' .. config.strategy .. '", falling back to legacy', vim.log.levels.WARN)
		layout = code_layout:new(language_config, config.indent_width)
	end

	layout:update()

	local buffer_keymap_manager = make_buffer_keymap_manager(layout)
	key_mapping.setup_keymaps(buffer_keymap_descriptions, buffer_keymap_manager, config.keymaps)

	return layout
end

---@return KeymapManager
local function make_master_keymap_manager(config)
	local layout = nil
	return {
		keymap_callbacks = {
			open_layout = { callback = function()
				if layout == nil or not vim.api.nvim_win_is_valid(layout.scratch_win) then
					layout = create_layout(config)
				else
					if vim.api.nvim_get_current_buf() ~= layout.source_buf then
						layout:close_code_layout_window()
						layout = create_layout(config)
					else
						vim.api.nvim_set_current_win(layout.scratch_win)
					end
				end
			end, opts = {} },
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
