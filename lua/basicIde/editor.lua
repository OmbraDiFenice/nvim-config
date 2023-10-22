local close_current_buffer = function()
	local bufs = vim.fn.getbufinfo()
	local current_buffer = vim.api.nvim_win_get_buf(0)
	local current_buffer_idx = nil

	for i, buf_info in ipairs(bufs) do
		if buf_info.bufnr == current_buffer then
			current_buffer_idx = i
		end
	end

	if current_buffer_idx == nil then
		vim.api.nvim_err_writeln('unable to find current buffer index')
		return
	end

	local prev_buf = nil
	local next_buf = nil

	for i = current_buffer_idx - 1, 0, -1 do
		local buf = bufs[i]
		if buf ~= nil and buf.listed == 1 then
			prev_buf = buf.bufnr
			break
		end
	end

	for i = current_buffer_idx + 1, #bufs, 1 do
		local buf = bufs[i]
		if buf ~= nil and buf.listed == 1 then
			next_buf = buf.bufnr
			break
		end
	end

	vim.api.nvim_buf_delete(current_buffer, { unload = false })

	if prev_buf then
		vim.cmd('buffer ' .. prev_buf)
	else
		if next_buf then
			vim.cmd('buffer ' .. next_buf)
		end
	end
end

local function close_all()
	for _, tab_info in ipairs(vim.fn.gettabinfo()) do
		for variable, value in pairs(tab_info.variables or {}) do
			if variable == 'diffview_tab' and value == true then -- variable is set in git.lua, during diffview hook
				vim.cmd(':tabclose ' .. tab_info.tabnr)
			end
		end
	end
	vim.cmd [[ qall ]]
end

local function setup_diagnostics_keybindings()
	vim.api.nvim_set_keymap('n', '<leader>d?', '', {
		callback = vim.diagnostic.open_float,
		desc = 'open diagnostic floating window for current line',
	})

	vim.api.nvim_set_keymap('n', '<C-l>', '', {
		callback = function()
			require('telescope.builtin').diagnostics()
		end,
		desc = 'show diagnostics for all loaded buffers',
	})
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
		vim.keymap.set('n', '<leader>Q', close_all, { desc = 'close all windows' })

		-- opens help windows on the right, taken from https://vi.stackexchange.com/questions/4452/how-can-i-make-vim-open-help-in-a-vertical-split
		local vimrc_help_group = vim.api.nvim_create_augroup('vimrc_help', { clear = true })
		vim.api.nvim_create_autocmd({ 'BufEnter' }, {
			desc = 'Move opened help windows to the right',
			group = vimrc_help_group,
			pattern = '*.txt',
			callback = function(args)
				if vim.api.nvim_buf_get_option(args.buf, 'buftype') == 'help' then
					vim.cmd 'wincmd L'
				end
			end
		})

		setup_diagnostics_keybindings()
	end
}
