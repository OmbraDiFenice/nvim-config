return {
	use_deps = function(use)
		use 'elentok/format-on-save.nvim'
	end,

	configure = function()
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
