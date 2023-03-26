return {
	use_deps = function(use)
		use {
			'tpope/vim-fugitive',
		}
		use {
			'lewis6991/gitsigns.nvim',
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
				end, {expr=true})

				map('n', '[c', function()
					if vim.wo.diff then return '[c' end
					vim.schedule(function() gs.prev_hunk() end)
					return '<Ignore>'
				end, {expr=true})

				-- Actions
				map({'n', 'v'}, '<leader>hs', ':Gitsigns stage_hunk<CR>', { desc = 'stage hunk' })
				map({'n', 'v'}, '<leader>hr', ':Gitsigns reset_hunk<CR>', { desc = 'reset hunk' })
				map('n', '<leader>hp', gs.preview_hunk, { desc = 'git preview hunk' })
				map('n', '<leader>hS', gs.stage_buffer, { desc = 'git stage buffer' })
				map('n', '<leader>hu', gs.undo_stage_hunk, { desc = 'undo stage hunk' })
				map('n', '<leader>hR', gs.reset_buffer, { desc = 'git reset buffer' })
				map('n', '<leader>hd', gs.diffthis, { desc = 'git diff this' })
				map('n', '<leader>hD', function() gs.diffthis('~') end, { desc = 'git diff ~' })
			end
		}
	end,
}
