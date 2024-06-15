local language_modules = {
	require('basicIde.debugging.languages.python'),
	require('basicIde.debugging.languages.javascript'),
}

---@type IdeModule
return {
	use_deps = function(use)
		use {
			'mfussenegger/nvim-dap'
		}
		use {
			'rcarriga/nvim-dap-ui',
			requires = {
				'mfussenegger/nvim-dap',
				'nvim-neotest/nvim-nio',
			}
		}

		for _, language_module in ipairs(language_modules) do
			language_module.use_deps(use)
		end
	end,

	configure = function(project_settings)
		local setup_listeners = require('basicIde.debugging.events')
		local setup_project_settings = require('basicIde.debugging.project_settings')
		local setup_default_ui = require('basicIde.debugging.default_ui')

		setup_default_ui()
		setup_listeners()

		for _, language_module in ipairs(language_modules) do
			language_module.configure(project_settings)
		end

		-- this needs to be done after configuring all the language language modules
		-- otherwise the default dap configurations created by the modules will not exist yet
		-- and they need to be patched as well (e.g. to set/extend the environment variables)
		setup_project_settings(project_settings)
	end
}
