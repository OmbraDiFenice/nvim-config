local utils = require('basicIde.utils')

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

local function make_popup_menu_entry(title, command, opts)
	opts = opts or {}
	opts.icon = "󰃤"
	utils.popup_menu.make_entry(title, command, opts)
end

local function setup_mouse_menu()
	make_popup_menu_entry("---")
	make_popup_menu_entry("Toggle breakpoint", "lua require('dap').toggle_breakpoint()")
	make_popup_menu_entry("Toggle conditional breakpoint", "lua require('dap').toggle_breakpoint(vim.fn.input({ prompt = 'Breakpoint condition: ' }))")

	local dap_session_en_cb = utils.popup_menu.make_enable_callback("DAP session", function() return require('dap').session() ~= nil end)
	make_popup_menu_entry("Run to cursor", "lua require('dap').run_to_cursor()", { enabled_by = dap_session_en_cb })
	make_popup_menu_entry("Send to repl", "lua require('basicIde.debugging.operations').send_to_repl()", { mode = "v", enabled_by = dap_session_en_cb })
	make_popup_menu_entry("Evaluate", "lua require('dapui').eval(nil)", { enabled_by = dap_session_en_cb })
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

	vim.fn.sign_define('DapBreakpoint', { text = '', texthl = 'DapUIStop', linehl = '', numhl = '' })
	vim.fn.sign_define('DapBreakpointCondition', { text = '', texthl = 'DapUIStop', linehl = '', numhl = '' })

	vim.fn.sign_define('DapLogPoint', { text = '', texthl = 'DapUIStop', linehl = '', numhl = '' })
	vim.fn.sign_define('DapBreakpointRejected', { text = '', texthl = 'DapUIStop', linehl = '', numhl = '' })

	setup_keymaps()
	setup_mouse_menu()

	vim.api.nvim_create_autocmd('BufWinEnter', {
		callback = function(e)
			local bufnr = e.buf
			local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
			if not utils.tables.is_in_list(filetype, { "dap-repl", "dapui_watches", "dapui_stacks", "dapui_scopes" }) then
				return
			end
			local windows = vim.fn.win_findbuf(bufnr)
			for _, win in ipairs(windows) do
				for opt, value in pairs(utils.vim.minimal.wo) do
					vim.api.nvim_set_option_value(opt, value, { win = win })
				end
			end
		end,
	})

end
