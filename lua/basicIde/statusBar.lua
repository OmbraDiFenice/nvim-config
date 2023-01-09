return {
	use_deps = function(use)
		use {
			'nvim-lualine/lualine.nvim',
			requires = { 'kyazdani42/nvim-web-devicons', opt = true }
		}
	end,

	configure = function()
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
		}
	end,
}
