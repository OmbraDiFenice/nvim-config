return {
	use_deps = function()
	end,

	configure = function()
		vim.cmd [[ set hlsearch ]]
		vim.cmd [[ set number relativenumber ]]
		vim.cmd [[ autocmd BufReadPost * silent! normal! g`"zv ]]

		vim.cmd [[ set tabstop=2 ]]
		vim.cmd [[ set shiftwidth=2 ]]
		vim.cmd [[ set noexpandtab ]]

		vim.g.mapleader = ' '
		vim.g.maplocalleader = ' '

		vim.o.updatetime = 300
		vim.wo.signcolumn = 'yes'

		vim.cmd [[ set clipboard+=unnamedplus ]]

		vim.api.nvim_set_keymap("c", "h", "vertical botright h", { noremap = true, desc = "open help in a right vertical split window" })
	end,
}
