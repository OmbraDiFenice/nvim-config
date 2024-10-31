local utils = require('basicIde.utils')

---@type IdeModule
return {
	use_deps = function(use)
		use 'Exafunction/codeium.vim'
	end,

	configure = function(project_settings)
		local config = project_settings.ai

		vim.g.codeium_enabled = config.enabled
		vim.g.codeium_manual = config.manual
		vim.g.codeium_render = config.render_suggestion

		vim.g.codeium_disable_bindings = true
		for _, shortcut in ipairs(config.keymaps.accept_current_suggestion) do vim.keymap.set('i', shortcut, function() return vim.fn['codeium#Accept']() end, { expr = true, silent = true, desc = 'Accept AI suggestion'}) end
		for _, shortcut in ipairs(config.keymaps.next_suggestion) do vim.keymap.set('i', shortcut, function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true, silent = true, desc = 'Next AI suggestion'}) end
		for _, shortcut in ipairs(config.keymaps.previous_suggestion) do vim.keymap.set('i', shortcut, function() return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true, silent = true, desc = 'Previous AI suggestion'}) end
		for _, shortcut in ipairs(config.keymaps.clear_current_suggestion) do vim.keymap.set('i', shortcut, function() return vim.fn['codeium#Clear']() end, { expr = true, silent = true, desc = 'Clear AI suggestion'}) end

		vim.g.codeium_disable_for_all_filetypes = config.disable_for_all_filetypes
		local default_filetype = {
			TelescopePrompt = false,
		}
		vim.g.codeium_filetypes = utils.tables.deepmerge(default_filetype, config.filetypes)
	end
}
