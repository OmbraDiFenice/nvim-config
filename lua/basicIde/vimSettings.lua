---@type IdeModule
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

		vim.cmd [[ set splitright ]]

		vim.g.mapleader = ' '
		vim.g.maplocalleader = ' '

		vim.o.updatetime = 300
		vim.wo.signcolumn = 'yes'

		vim.cmd [[ set clipboard+=unnamedplus ]]

		vim.cmd [[ set listchars=eol:¬,tab:>·,trail:~,extends:>,precedes:<,space:␣ ]] -- enable with :set list, disable with :set nolist
	end,
}
