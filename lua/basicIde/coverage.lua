local setup_keymaps = function()
	local coverage = require('coverage')
	local report = require('coverage.report')
	local config = require('coverage.config')

	---Calls `cb` making sure that the coverage data are loaded first.
	---This is necessary because the plugin doesn't load them until they're required
	---but then if we call functions to access the coverage data they'll get empty result
	---because the data is loaded asynchronously.
	---@param cb fun(): nil
	local ensureLoaded = function(cb)
		if not report.is_cached() then
			local cb_orig = config.opts.load_coverage_cb
			if cb_orig == nil then
				cb_orig = function() end
			end

			config.opts.load_coverage_cb = function(cb_arg)
				cb()
				cb_orig(cb_arg)
				config.opts.load_coverage_cb = cb_orig
			end

			coverage.load(false)
		else
			cb()
		end
	end

	vim.keymap.set('n', '<leader>ct', function()
		ensureLoaded(coverage.toggle)
	end, { desc = 'Toggle coverage gutter' })
	vim.keymap.set('n', '<leader>cs', function()
		ensureLoaded(coverage.summary)
	end, { desc = 'Show coverage summary' })
end

---@type IdeModule
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
