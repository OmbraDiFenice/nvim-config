local UNITTEST_TERM_ID = 10

local function parseCommand(commandDescriptor)
	local cmd = ""

	if commandDescriptor.virtualEnv then
		cmd = cmd .. "[[ -z ${VIRTUAL_ENV:+x} ]] || source " .. commandDescriptor.virtualEnv .. "; "
	end

	for key, value in pairs(commandDescriptor.env) do
		cmd = cmd .. key .. "=" .. value .. " "
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
			},
		})
	end,
}
