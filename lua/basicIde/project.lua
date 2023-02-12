local UNITTEST_TERM_ID = 10
local CUSTOM_COMMAND_TERM_ID = 11

local function parseCommand(commandDescriptor)
	local cmd = ""

	if commandDescriptor.virtualEnv then
		cmd = cmd .. "source " .. commandDescriptor.virtualEnv .. "; "
	end

	cmd = cmd .. commandDescriptor.cmd

	return cmd
end


return {
	use_deps = function(use)
		use {
			'VonHeikemen/project-settings.nvim',
			requires = {
				'akinsho/toggleterm.nvim' -- not really required by the plugin, but used to start commands in terminal
			}
		}
	end,

	configure = function()
		local projectSettings = require('project-settings')

		projectSettings.setup({
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

						local terminal = require('toggleterm.terminal').Terminal:new {
							cmd = cmd,
							dir = commandDescriptor.workDir,
							env = commandDescriptor.env,
							close_on_exit = false,
						}

						terminal:open(20)
					end,
					{ desc = 'Run custom script' })
				end,
			},
		})

		local project_cmds = vim.api.nvim_create_augroup('project_cmds', {clear = true})
		local autocmd = vim.api.nvim_create_autocmd

		autocmd('BufWritePost', {
			pattern = '.vimrc.json',
			group = project_cmds,
			callback = function()
				vim.cmd [[ silent ProjectSettingsRegister ]]
				projectSettings.load({ force = true })
			end
		})
	end,
}
