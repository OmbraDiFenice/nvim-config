return {
	use_deps = function(use)
		use {
			'akinsho/toggleterm.nvim',
		}
	end,

	configure = function()

		local Terminal = require('toggleterm.terminal').Terminal
		local lazygit = Terminal:new({
			cmd = 'lazygit --use-config-dir ~/.config/nvim/lua/basicIde/lazygitConfigDir || exit 100',
			hidden = true,
			direction = 'float',
			close_on_exit = true,
			on_exit = function (_, _, exit_code)
				if exit_code == 100 then
					vim.api.nvim_err_writeln('Please install lazygit executable. See https://github.com/jesseduffield/lazygit#installation')
				end
			end

		})

		vim.keymap.set('n', '<leader>g', function() lazygit:toggle() end, { desc = 'Open lazygit in terminal' })

	end,
}
