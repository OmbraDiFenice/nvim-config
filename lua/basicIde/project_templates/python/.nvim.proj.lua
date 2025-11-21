---@diagnostic disable: unused-local, missing-fields
---@type ProjectSettings
return {
	project_languages = {"python"},
	loader = {
		virtual_environment = "venv",
		environment = {
			PYTHONPATH = "${ide:PROJECT_ROOT}/src:${env:PYTHONPATH}",
		},
	},
	debugging = {
		dap_configurations = {
			python = {
				{
					keymap = "<S-F9>",
					type = "python",
					name = "sample configuration",
					request = "launch",
					program = "main.py",
					console = "integratedTerminal",
					cwd = "${ide:PROJECT_ROOT}",
				},
				{
					keymap = "<F9>",
					type = "python",
					name = "Unit tests",
					request = "launch",
					module = "unittest",
					args = "discover -s ${ide:PROJECT_ROOT}/tests",
					console = "integratedTerminal",
					cwd = "${ide:PROJECT_ROOT}",
				},
			},
		},
	},
}
