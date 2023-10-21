local setup_keymaps = function()
	local coverage = require('coverage')
	local report = require('coverage.report')
	local config = require('coverage.config')

	local ensureLoaded = function (cb)
		if not report.is_cached() then
			local cb_orig = config.opts.load_coverage_cb

			config.opts.load_coverage_cb = function(cb_arg)
				cb()
				if cb_orig ~= nil then
					cb_orig(cb_arg)
				end
				config.opts.load_coverage_cb = cb_orig
			end

			coverage.load(false)
		else
			cb()
		end
	end

	vim.keymap.set('n', '<leader>ct', function ()
		ensureLoaded(coverage.toggle)
	end, { desc = 'Toggle coverage gutter' })
	vim.keymap.set('n', '<leader>cs', function ()
		ensureLoaded(coverage.summary)
	end, { desc = 'Show coverage summary' })
end

return {
	use_deps = function(use)
		use({
			"andythigpen/nvim-coverage",
			requires = "nvim-lua/plenary.nvim",
			-- Optional: needed for PHP when using the cobertura parser
			rocks = { 'lua-xmlreader' },
		})
	end,

	configure = function()
		require("coverage").setup({
			auto_reload = true,
		})
		setup_keymaps()
	end
}
