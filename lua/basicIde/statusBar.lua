TestRun_lualine_component = {
	msg = '',
}

function TestRun_lualine_component:init()
	vim.cmd [[ highlight! lualine_test_passed guifg=#98c379 guibg=#31353f ]]
	vim.cmd [[ highlight! lualine_test_failed guifg=#e86671 guibg=#31353f ]]

	vim.api.nvim_create_autocmd('User', {
		pattern = 'UpdateTestStatusBar',
		callback = function(data)
			self.msg = data.data.message
			require('lualine').refresh()
		end
	})
end

return {
	use_deps = function(use)
		use {
			'nvim-lualine/lualine.nvim',
			requires = { 'kyazdani42/nvim-web-devicons' }
		}
	end,

	configure = function()
		TestRun_lualine_component:init()

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
				},
				lualine_x = { function() return TestRun_lualine_component.msg end, 'encoding', 'fileformat', 'filetype' },
			}
		}
	end,
}
