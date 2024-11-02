local key_mapping = require('basicIde.key_mapping')

local keymap_descriptions = {
	format_current_buffer = 'Format current buffer with LSP',
}

---@type KeymapManager
local keymap_manager = {
	keymap_callbacks = {
		format_current_buffer = { callback = vim.lsp.buf.format, opts = {} },
	},
}


---@type IdeModule
return {
	use_deps = function(use, project_settings)
		if not project_settings.format_on_save.enabled then return end

		use 'elentok/format-on-save.nvim'
	end,

	configure = function(project_settings)
		if not project_settings.format_on_save.enabled then return end

		key_mapping.setup_keymaps(keymap_descriptions, keymap_manager, project_settings.format_on_save.keymaps)

		local format_on_save = require("format-on-save")
		local formatters = require("format-on-save.formatters")

		format_on_save.setup({
			exclude_path_patterns = {
				"/node_modules/",
				".local/share/nvim/lazy",
				"/venv/",
				"/venvLinux/",
			},
			formatter_by_ft = {
			},
			fallback_formatter = {
				formatters.lsp,
			},
			experiments = {
				disable_restore_cursors = true,
			},
		})
	end,
}
