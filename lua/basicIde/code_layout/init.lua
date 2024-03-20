local utils = require('basicIde.utils')
local code_layout = require('basicIde.code_layout.code_layout')

---@type IdeModule
return {
	use_deps = function()
	end,

	configure = function(project_settings)
		local config = project_settings.code_layout

		vim.keymap.set('n', '<leader>l', function ()
			local filetype = vim.bo.filetype
			local language_config = config.languages[filetype]
			if language_config == nil then
				vim.notify('Code layout for language "' .. filetype .. '" not configured', vim.log.levels.WARN)
				return
			end

			local layout = code_layout:new(language_config, config.indent_width)
			layout:update()

			for mode_shortcut, keymap_def in pairs(config.keymaps) do
				local mode, shortcut, callback, desc = utils.parse_custom_keymap_config(mode_shortcut, keymap_def)
				vim.api.nvim_buf_set_keymap(layout:get_buf(), mode, shortcut, '', {
					callback = function() callback(layout) end,
					desc = desc,
				})
			end
		end, { desc = 'show current file layout' })
	end
}
