local dap = require('dap')
local dapui = require('dapui')

local function update_lualine_test_started(session)
	vim.api.nvim_exec_autocmds('User', {
		pattern = 'UpdateTestStatusBar',
		data = { message = '' },
	})
end

local function update_lualine_test_end(session, data)
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

return function()
	-- these are tables so that if we run this function multiple times
	-- (e.g. by sourcing the file) we don't attach new functions to the same event again
	dap.listeners.after.event_stopped['dapui_config'] = dapui.open

	dap.listeners.before.event_terminated['dapui_config'] = dapui.close

	dap.listeners.before.event_exited['dapui_config'] = function(session, data)
		dapui.close()

		if session.config.unittest then -- unittest is a custom key extra key, not part of the standard api
			update_lualine_test_end(session, data)
		end
	end

	dap.listeners.after.event_process['dapui_config'] = function(session)
		if session.config.unittest then -- unittest is a custom key extra key, not part of the standard api
			update_lualine_test_started(session)
		end
	end
end
