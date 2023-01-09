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
	end,
}
