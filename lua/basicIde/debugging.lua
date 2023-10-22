local setup_keymaps = function()
	local dap = require('dap')
	local dapui = require('dapui')

	-- debugger actions (see :h dap-mappings for more examples)
	vim.keymap.set('n', '<F5>', function() dap.continue() end, { desc = 'start/continue debugging execution' })
	vim.keymap.set('n', '<F2>', function() dap.step_over() end, { desc = 'debuger step over' })
	vim.keymap.set('n', '<F3>', function() dap.step_into() end, { desc = 'debuger step into' })
	vim.keymap.set('n', '<F4>', function() dap.step_out() end, { desc = 'debuger step out' })
	vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Toggle breakpoint' })
	vim.keymap.set('n', '<leader>dB', function()
		dap.toggle_breakpoint(vim.fn.input({ prompt = 'Breakpoint condition: ' }))
	end, { desc = 'Toggle conditional breakpoint' })
	vim.keymap.set('n', '<leader>dq', dap.terminate, { desc = 'Stop debug session' })

	-- debugger UI
	vim.keymap.set('n', '<leader>dd', dapui.toggle, { desc = 'Toggle debugger' })
	vim.keymap.set('n', '<leader>dl', function()
		dapui.float_element('breakpoints', { width = 100, height = 40, enter = true })
	end, { desc = 'Show breakpoint list' })
	vim.keymap.set('n', '<leader>dc', function()
		dapui.float_element('console', { width = 130, height = 60 })
	end, { desc = 'Show debugging console output' })
end

local setup_listeners = function()
	local dap = require('dap')
	local dapui = require('dapui')

	-- these are tables so that if we run this function multiple times
	-- (e.g. by sourcing the file) we don't attach new functions to the same event again
	dap.listeners.after.event_stopped['dapui_config'] = dapui.open
	dap.listeners.before.event_terminated['dapui_config'] = dapui.close
	dap.listeners.before.event_exited['dapui_config'] = function(session, data)
		dapui.close()

		if session.config.unittest then -- unittest is a custom key extra key, not part of the standard api
			local testOutcome = {
				message = '%#lualine_test_passed#tests passed'
			}
			if data.exitCode ~= 0 then
				testOutcome.message = '%#lualine_test_failed#tests failed'
				dapui.float_element('console', { width = 130, height = 60 })
			end

			vim.api.nvim_exec_autocmds('User', {
				pattern = 'UpdateTestStatusBar',
				data = testOutcome,
			})
		end
	end
	dap.listeners.after.event_process['dapui_config'] = function(session)
		if session.config.unittest then -- unittest is a custom key extra key, not part of the standard api
			vim.api.nvim_exec_autocmds('User', {
				pattern = 'UpdateTestStatusBar',
				data = { message = '' },
			})
		end
	end
end

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

		-- javascript
		use {
			"mxsdev/nvim-dap-vscode-js",
			requires = {
				"microsoft/vscode-js-debug",
				opt = true,
				run = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
			}
		}
	end,

	configure = function()
		local dapui = require('dapui')
		dapui.setup {
			layouts = {
				{
					position = "right",
					size = 0.3,
					elements = {
						{
							id = 'scopes',
							size = 0.7,
						},
						{
							id = 'watches',
							size = 0.3,
						},
					},
				},
				{
					position = 'bottom',
					size = 10,
					elements = {
						{
							id = 'stacks',
							size = 0.3,
						},
						{
							id = 'repl',
							size = 0.7,
						},
					},
				},
			},
		}

		vim.fn.sign_define('DapBreakpoint', { text = '', texthl = '', linehl = '', numhl = '' })
		vim.fn.sign_define('DapBreakpointCondition', { text = '', texthl = '', linehl = '', numhl = '' })

		vim.fn.sign_define('DapLogPoint', { text = '', texthl = '', linehl = '', numhl = '' })
		vim.fn.sign_define('DapBreakpointRejected', { text = '', texthl = '', linehl = '', numhl = '' })

		setup_keymaps()
		setup_listeners()

		-- python configuration
		local dap_python = require('dap-python')
		dap_python.setup('~/.local/share/nvim/mason/packages/debugpy/venv/bin/python')

		-- javascript configuration
		local dap_vscode_js = require('dap-vscode-js')
		dap_vscode_js.setup({
			adapters = { 'pwa-node', 'pwa-chrome', 'node-terminal' },
		})
	end
}
