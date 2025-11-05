---@diagnostic disable: unused-local, missing-fields
---@type ProjectSettings
return {
	project_languages = {"python"},
	loader = {
		virtual_environment = "venv",
	},
	debugging = {
		dap_configurations = {
			python = {
				{
					keymap = "<F9>",
					type = "python",
					name = "sample configuration",
					request = "launch",
					program = "main.py",
					console = "integratedTerminal",
					cwd = "${ide:PROJECT_ROOT}",
				},
			},
		},
	},
}
