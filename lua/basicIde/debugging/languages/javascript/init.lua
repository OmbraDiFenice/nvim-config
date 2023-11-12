return {
	use_deps = function(use)
		use {
			"mxsdev/nvim-dap-vscode-js",
			requires = {
				"microsoft/vscode-js-debug",
				opt = true,
				run = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
			}
		}
	end,

	configure = function(project_settings)
		local dap_vscode_js = require('dap-vscode-js')
		dap_vscode_js.setup({
			adapters = { 'pwa-node', 'pwa-chrome', 'node-terminal' },
		})
	end
}
