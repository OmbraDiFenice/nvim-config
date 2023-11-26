---@param keymap_settings FormatOnSaveKeymapsSettings
local function setup_keymaps(keymap_settings)
	vim.keymap.set({'n', 'v'}, keymap_settings.format_current_buffer, vim.lsp.buf.format, { desc = 'format current buffer' })
end

---@type IdeModule
return {
	use_deps = function(use, project_settings)
		if not project_settings.format_on_save.enabled then return end

		use 'elentok/format-on-save.nvim'
	end,

	configure = function(project_settings)
		setup_keymaps(project_settings.format_on_save.keymaps)

		if not project_settings.format_on_save.enabled then return end

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
