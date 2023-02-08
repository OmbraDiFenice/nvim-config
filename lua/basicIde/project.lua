local UNITTEST_TERM_ID = 10
local CUSTOM_COMMAND_TERM_ID = 11

local function parseCommand(commandDescriptor)
	local cmd = ""

	if commandDescriptor.virtualEnv then
		cmd = cmd .. "[[ -z ${VIRTUAL_ENV:+x} ]] || source " .. commandDescriptor.virtualEnv .. "; "
	end

	if commandDescriptor.env then
		for key, value in pairs(commandDescriptor.env) do
			cmd = cmd .. key .. "=" .. value .. " "
		end
	end

	cmd = cmd .. commandDescriptor.cmd

	return cmd
end


return {
	use_deps = function(use)
		use 'VonHeikemen/project-settings.nvim'
	end,

	configure = function()
		require('project-settings').setup({
			allow = {
				unitTests = function(opts)
					local cmd = parseCommand(opts)

					vim.keymap.set('n', '<leader>t', function()
						require('toggleterm').exec(cmd, UNITTEST_TERM_ID, 20, opts.workDir)
					end,
					{ desc = 'Run unit tests' })
				end,

				customScript = function(opts)
					vim.keymap.set('n', '<leader>cs', function ()
						local i = vim.v.count
						local commandDescriptor = opts[i+1] -- lua tables indexes are 1-based

						if commandDescriptor == nil then
							print("no custom script registered at index " .. i)
							return
						end

						local cmd = parseCommand(commandDescriptor)
						require('toggleterm').exec(cmd, CUSTOM_COMMAND_TERM_ID + i, 20, commandDescriptor.workDir)
					end,
					{ desc = 'Run custom script' })
				end,
			},
		})
	end,
}
