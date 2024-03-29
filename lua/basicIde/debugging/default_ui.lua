local setup_keymaps = function()
	local dap = require('dap')
	local dapui = require('dapui')

	-- debugger actions (see :h dap-mappings for more examples)
	vim.keymap.set('n', '<F5>', function() dap.continue() end, { desc = 'start/continue debugging execution' })
	vim.keymap.set('n', '<F2>', function() dap.step_over() end, { desc = 'debugger step over' })
	vim.keymap.set('n', '<F3>', function() dap.step_into() end, { desc = 'debugger step into' })
	vim.keymap.set('n', '<F4>', function() dap.step_out() end, { desc = 'debugger step out' })
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

return function()
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
end
