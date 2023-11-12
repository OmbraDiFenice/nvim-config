local setup_listeners = require('basicIde.debugging.events')
local setup_project_settings = require('basicIde.debugging.project_settings')
local setup_default_ui = require('basicIde.debugging.default_ui')

local language_modules = {
	require('basicIde.debugging.languages.python'),
	require('basicIde.debugging.languages.javascript'),
}

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

		for _, language_module in ipairs(language_modules) do
			language_module.use_deps(use)
		end
	end,

	configure = function(project_settings)
		setup_default_ui()
		setup_listeners()

		setup_project_settings(project_settings)

		-- this must be done after the generic configurations are done
		-- particularly after applying project settings
		for _, language_module in ipairs(language_modules) do
			language_module.configure(project_settings)
		end
	end
}
