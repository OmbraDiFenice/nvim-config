local dap = require('dap')
local dapui = require('dapui')
local coverage = require('coverage')
local utils = require('basicIde.utils')

---Update status in lualine when a dap configuration starts.
---This is useful when you run tests multiple times, otherwise you might still have the last outcome displayed
---and not know exactly if you triggered the tests or not.
---@param session DapSessionExtended
---@return nil
local function update_lualine_run_started(session)
	utils.update_lualine_debug_status('Running ' .. session.config.name)
end

---Update status in lualine when a dap configuration ends.
---This can display the outcome of test executions
---@param session DapSessionExtended
---@param data any
---@return nil
local function update_lualine_run_end(session, data)
	local testOutcome = session.config.name .. ': success'
	local color = 'lualine_test_passed'

	if data.exitCode ~= 0 then
		testOutcome = session.config.name .. ': failed'
		color = 'lualine_test_failed'
		dapui.float_element('console', { width = 130, height = 60, enter = true })
	end

	utils.update_lualine_debug_status(testOutcome, color)
end

---Update the coverage information. Clears them in case the execution failed
---@param session DapSessionExtended
---@param data any
local function update_coverage_signs(session, data)
	if data.exit_code == 0 then
		local signs = require('coverage.signs')
		coverage.load(signs.is_enabled())
	else
		coverage.clear()
	end
end

return function()
	-- these are tables so that if we run this function multiple times
	-- (e.g. by sourcing the file) we don't attach new functions to the same event again
	dap.listeners.after.event_stopped['dapui_config'] = dapui.open

	dap.listeners.before.event_terminated['dapui_config'] = dapui.close

	---@param session DapSessionExtended
	---@param data any
	dap.listeners.before.event_exited['dapui_config'] = function(session, data)
		dapui.close()

		update_lualine_run_end(session, data)

		if session.is_coverage then -- is_coverage is a custom extra key, not part of the standard api
			update_coverage_signs(session, data)
		end
	end

	---@param session DapSessionExtended
	dap.listeners.after.event_process['dapui_config'] = function(session)
		update_lualine_run_started(session)
	end
end
