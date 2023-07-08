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

		-- opens help windows on the right, taken from https://vi.stackexchange.com/questions/4452/how-can-i-make-vim-open-help-in-a-vertical-split
		vim.cmd [[
			augroup vimrc_help
				autocmd!
				autocmd BufEnter *.txt if &buftype == 'help' | wincmd L | endif
			augroup END
		]]
	end,
}
