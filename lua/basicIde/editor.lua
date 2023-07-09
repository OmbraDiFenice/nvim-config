local close_current_buffer = function()
	local bufs = vim.fn.getbufinfo({ buflisted = true })
	local current_buffer = vim.api.nvim_win_get_buf(0)
	local current_buffer_idx = nil

	for i, buf_info in ipairs(bufs) do
		if buf_info.bufnr == current_buffer then
			current_buffer_idx = i
		end
	end

	if current_buffer_idx == nil then
		vim.api.nvim_err_writeln('unable to find current buffer index. Maybe it is not listed?')
		return
	end

	local prev = bufs[current_buffer_idx-1] ~= nil and bufs[current_buffer_idx-1].bufnr
	local next = bufs[current_buffer_idx+1] ~= nil and bufs[current_buffer_idx+1].bufnr

	if prev then
		vim.cmd('buffer '..prev)
	else
		if next then
			vim.cmd('buffer '..next)
		end
	end
	vim.api.nvim_buf_delete(current_buffer, { unload = false })
end

return {
	use_deps = function(use)
		use {
			'Pocco81/auto-save.nvim',
		}
	end,

	configure = function()
		require('auto-save').setup()

		vim.keymap.set("n", "<leader>q", close_current_buffer, { silent = true, noremap = true, desc = "close buffer" })
		vim.keymap.set('n', '<leader>Q', function() vim.cmd('qall') end, { desc = 'close window' })

		-- opens help windows on the right, taken from https://vi.stackexchange.com/questions/4452/how-can-i-make-vim-open-help-in-a-vertical-split
		local vimrc_help_group = vim.api.nvim_create_augroup('vimrc_help', { clear = true })
		vim.api.nvim_create_autocmd( { 'BufEnter' }, {
			desc = 'Move opened help windows to the right',
			group = vimrc_help_group,
			pattern = '*.txt',
			callback = function (args)
				if vim.api.nvim_buf_get_option(args.buf, 'buftype') == 'help' then
					vim.cmd 'wincmd L'
				end
			end
		})
	end
}
