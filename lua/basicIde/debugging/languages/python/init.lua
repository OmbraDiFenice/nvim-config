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
	end
}
