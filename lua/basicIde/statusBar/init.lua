local CodeBreadcrumbs = require('basicIde.statusBar.lualine_components.code_breadcrumbs')
local TestRun = require('basicIde.statusBar.lualine_components.test_run')

---@type IdeModule
return {
	use_deps = function(use)
		use {
			'nvim-lualine/lualine.nvim',
			requires = { 'kyazdani42/nvim-web-devicons' }
		}
	end,

	configure = function(project_settings)
		local testRun = TestRun:new()
		local breadcrumbs = CodeBreadcrumbs:new()

		local right_side = {
			function() return testRun.msg end,
		}

		if project_settings.ai.enabled and project_settings.ai.show_in_status_bar then
			table.insert(right_side, function()
				local success, res = pcall(vim.fn['codeium#GetStatusString'])
				if not success then return '' end
				return res
			end)
		end

		table.insert(right_side, 'encoding')
		table.insert(right_side, 'fileformat')
		table.insert(right_side, 'filetype')

		require('lualine').setup {
			options = {
				-- to enable fancy fonts in the terminal follow these steps:
				--   1. choose and download a monospace regular font from https://github.com/ryanoasis/nerd-fonts#patched-fonts
				--   2. copy the downloaded font in the user fonts directory
				--      On linux it can be any subfolder of ~/.local/share/fonts/
				--   3. [linux] refresh the font cache with `fc-cache`
				--   4. set the new font as default font used by your terminal
				-- steps taken from https://github.com/ryanoasis/nerd-fonts/blob/master/install.sh#L214
				icons_enabled = true,
				theme = 'onedark',
			},
			sections = {
				lualine_c = {
					{
						'filename',
						path = 1,
					},
					function() return breadcrumbs.msg end,
				},
				lualine_x = right_side,
			}
		}
	end,
}
