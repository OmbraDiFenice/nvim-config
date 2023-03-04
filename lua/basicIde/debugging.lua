return {
	use_deps = function(use)
		use {
			'mfussenegger/nvim-dap'
		}
		use {
			'rcarriga/nvim-dap-ui',
			requires = {
				'mfussenegger/nvim-dap'
			}
		}

	-- python
		use {
			'mfussenegger/nvim-dap-python',
			requires = {
				'nvim-treesitter/nvim-treesitter',
			}
		}
	end,

	configure = function()
		local dap = require('dap')
		local dapui = require("dapui")
		dapui.setup()

		vim.keymap.set('n', '<leader>dd', dapui.toggle, { desc = 'Toggle debugger' })
		vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Toggle debugger' })

		local dap_python = require('dap-python')
		dap_python.setup('~/.local/share/nvim/mason/packages/debugpy/venv/bin/python')
	end
}
