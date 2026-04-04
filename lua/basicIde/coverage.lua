local utils = require('basicIde.utils')

local ensure_coverage_setup = utils.once(function()
	require("coverage").setup({
		auto_reload = true,
	})
end)

local setup_keymaps = function()
	local function with_coverage(cb)
		ensure_coverage_setup()

		local coverage = require('coverage')
		local report = require('coverage.report')
		local config = require('coverage.config')

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
		with_coverage(function() require('coverage').toggle() end)
	end, { desc = 'Toggle coverage gutter' })
	vim.keymap.set('n', '<leader>cs', function()
		with_coverage(function() require('coverage').summary() end)
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
		setup_keymaps()
	end
}
