local function setup_keymaps()
	vim.keymap.set({'n', 'v'}, '<F7>', vim.lsp.buf.format, { desc = 'format current buffer' })
end

return {
	use_deps = function(use, project_settings)
		if not project_settings.format_on_save.enabled then return end

		use 'elentok/format-on-save.nvim'
	end,

	configure = function(project_settings)
		setup_keymaps()

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
