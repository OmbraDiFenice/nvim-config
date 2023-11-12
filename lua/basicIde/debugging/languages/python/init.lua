local dap = require('dap')

local function run_with_coverage(dap_configuration)
	local coverage_configuration = Deepcopy(dap_configuration)
	coverage_configuration.name = dap_configuration.name .. ' with coverage'
	coverage_configuration.args = { 'run', '-m', dap_configuration.module, }
	for _, arg in ipairs(dap_configuration.args) do
		table.insert(coverage_configuration.args, arg)
	end
	coverage_configuration.module = 'coverage'
	coverage_configuration.is_coverage = true

	dap.run(coverage_configuration)
end

local function add_run_debug_with_coverage_keymaps()
	for language, dap_configs in pairs(dap.configurations) do
		if language == 'python' then
			for _, dap_config in ipairs(dap_configs) do
				if dap_config.keymap_coverage then
					vim.keymap.set('n', dap_config.keymap_coverage, function() run_with_coverage(dap_config) end,
						{ desc = '[' .. dap_config.type .. ']' .. ' debug with coverage: ' .. dap_config.name })
				end
			end
		end
	end
end

return {
	use_deps = function(use)
		use {
			'mfussenegger/nvim-dap-python',
			requires = {
				'nvim-treesitter/nvim-treesitter',
			}
		}
	end,

	configure = function(project_settings)
		local dap_python = require('dap-python')
		dap_python.setup('~/.local/share/nvim/mason/packages/debugpy/venv/bin/python')

		-- requires that all the dap configurations, including the ones from project settings, are already registered in nvim dap.configurations
		add_run_debug_with_coverage_keymaps()
	end
}
