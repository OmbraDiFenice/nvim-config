---Originally the purpose was to open the commit win in a custom float window, but turns out that
---doing git editing inside the current nvim instance is more challenging that expected.
---For now just add some convenience wrappers around the fugitive command
---@param options? string # simple string of options to append after `git commit`
local function open_commit_win(options)
	if options == nil then options = '' end

	vim.api.nvim_command('Git commit ' .. options)
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	vim.api.nvim_command('startinsert')
	--vim.api.nvim_buf_set_var(buf, 'nvim_ide_autosave', false)
end

local function setup_diffview_keymaps()
	vim.keymap.set('n', '<leader>gd', function() vim.cmd [[ :DiffviewOpen ]] end, { desc = 'Open git diff' })
	vim.keymap.set({ 'n', 'v' }, '<leader>gh', function() vim.cmd [[ :DiffviewFileHistory ]] end,
		{ desc = 'Open git file/lines history' })
end

---@type IdeModule
return {
	use_deps = function(use)
		use {
			'tpope/vim-fugitive',
		}
		use {
			'lewis6991/gitsigns.nvim',
		}
		use {
			"sindrets/diffview.nvim",
		}
	end,

	configure = function()
		require('gitsigns').setup {
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					opts.silent = true
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation
				map('n', ']c', function()
					if vim.wo.diff then return ']c' end
					vim.schedule(function() gs.next_hunk() end)
					return '<Ignore>'
				end, { expr = true, desc = 'goto next hunk' })

				map('n', '[c', function()
					if vim.wo.diff then return '[c' end
					vim.schedule(function() gs.prev_hunk() end)
					return '<Ignore>'
				end, { expr = true, desc = 'goto previous hunk' })

				-- Actions
				map({ 'n', 'v' }, '<leader>hs', ':Gitsigns stage_hunk<CR>', { desc = 'stage hunk' })
				map({ 'n', 'v' }, '<leader>hr', ':Gitsigns reset_hunk<CR>', { desc = 'reset hunk' })
				map('n', '<leader>hp', gs.preview_hunk, { desc = 'git preview hunk' })
				map('n', '<leader>hS', gs.stage_buffer, { desc = 'git stage buffer' })
				map('n', '<leader>hu', gs.undo_stage_hunk, { desc = 'undo stage hunk' })
				map('n', '<leader>hR', gs.reset_buffer, { desc = 'git reset buffer' })
				map('n', '<leader>hd', gs.diffthis, { desc = 'git diff this' })
				map('n', '<leader>hD', function() gs.diffthis('~') end, { desc = 'git diff ~' })
			end
		}

		-- diffview

		require('diffview').setup {
			keymaps = {
				view = { { 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } } },
				diff1 = { { 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } } },
				diff2 = { { 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } } },
				diff3 = { { 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } } },
				diff4 = { { 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } } },
				file_panel = {
					{ 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } } },
				file_history_panel = {
					{ 'n', '<leader>q', function() vim.cmd [[ :tabclose ]] end, { desc = 'Diffview: Close current tab' } } },
			},
			hooks = {
				view_opened = function(view)
					vim.api.nvim_tabpage_set_var(view.tabpage, 'diffview_tab', true)
				end,
			},
		}
		setup_diffview_keymaps()

		vim.keymap.set('n', '<leader>gc', open_commit_win, { desc = 'git commit' })
		vim.keymap.set('n', '<leader>gca', function() open_commit_win('--amend') end, { desc = 'git commit --amend' })
		vim.keymap.set('n', '<leader>gcan', function() open_commit_win('--amend --no-edit') end, { desc = 'git commit --amend --no-edit ' })
	end,
}
